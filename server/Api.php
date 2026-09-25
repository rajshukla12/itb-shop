<?php
defined('BASEPATH') OR exit('No direct script access allowed');

/**
 * Mobile app JSON API for the iTechBuilders shop (Flutter Android/iOS).
 * Public, read-mostly. Reuses the existing tables: productss, product_categories,
 * product_images, manage_slider, manage_signup. Orders from the app go to app_orders.
 *
 * Base: https://www.itechbuilders.com/index.php/api/<endpoint>   (or /api/<endpoint> if index.php is hidden)
 */
class Api extends CI_Controller
{
	public function __construct()
	{
		parent::__construct();
		header('Access-Control-Allow-Origin: *');
		header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
		header('Access-Control-Allow-Headers: Content-Type, X-App-Token');
		header('Content-Type: application/json; charset=utf-8');
		if ($this->input->method() === 'options') { http_response_code(200); exit; }
		$this->ensure_tables();
	}

	/* ---------- helpers ---------- */

	private function out($data, $code = 200)
	{
		http_response_code($code);
		echo json_encode($data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRESERVE_ZERO_FRACTION);
		exit;
	}

	private function ok($data = array()) { $this->out(array('status' => 'success') + $data); }
	private function fail($msg, $code = 400) { $this->out(array('status' => 'error', 'message' => $msg), $code); }

	private function img($file, $folder = 'product')
	{
		$file = trim((string) $file);
		if ($file === '') return '';
		if (preg_match('#^https?://#i', $file)) return $file;
		return base_url('assets/images/'.$folder.'/'.$file);
	}

	/** JSON body OR normal POST */
	private function body()
	{
		$raw = json_decode((string) file_get_contents('php://input'), TRUE);
		return is_array($raw) ? array_merge($_POST, $raw) : $_POST;
	}

	private function product_row($p, $full = FALSE)
	{
		$price = (float) $p->price;
		$mrp   = (float) $p->real_price;
		$disc  = ($mrp > 0 && $mrp > $price) ? round(($mrp - $price) / $mrp * 100) : 0;
		$row = array(
			'id'         => (int) $p->id,
			'name'       => $p->name,
			'slug'       => $p->slug,
			'price'      => $price,
			'mrp'        => $mrp,
			'discount'   => $disc,
			'currency'   => $p->currency ?: 'INR',
			'sku'        => $p->sku,
			'image'      => $this->img($p->image),
			'in_stock'   => $this->in_stock($p),
			'stock_text' => (string) $p->stock_status,
			'short'      => trim((string) $p->short_description_text),
			'cat_id'     => (int) $p->cat_id,
			'sub_cat_id' => (int) $p->sub_cat_id,
		);
		if ($full)
		{
			$row['description_html'] = $p->description_html;
			$row['description']      = trim(strip_tags((string) $p->description_html)) ?: trim((string) $p->description_text);
			$gallery = array();
			foreach ($this->db->order_by('order_no', 'ASC')->get_where('product_images', array('product_id' => $p->id))->result() as $g)
				$gallery[] = $this->img($g->image);
			if ( ! $gallery && $row['image']) $gallery[] = $row['image'];
			$row['gallery'] = $gallery;
		}
		return $row;
	}

	private function in_stock($p)
	{
		$s = strtolower(trim((string) $p->stock_status));
		if ($s === '' ) return TRUE;
		if (is_numeric($s)) return (int) $s > 0;
		return ! in_array($s, array('out of stock', 'outofstock', 'out-of-stock', 'no', '0', 'unavailable'), TRUE);
	}

	/* ---------- endpoints ---------- */

	public function index() { $this->ok(array('name' => 'iTechBuilders API', 'version' => 1)); }
	public function ping()  { $this->ok(array('time' => date('c'))); }

	/** Home screen payload: sliders + top categories + featured products */
	public function home()
	{
		$sliders = array();
		foreach ($this->db->where('is_active', 1)->order_by('s_id', 'ASC')->get('manage_slider')->result() as $s)
			$sliders[] = array('title' => $s->slider_title, 'image' => $this->img($s->slider_pic, 'slider'), 'link' => $s->link);

		$cats = array();
		foreach ($this->db->where(array('level' => 1, 'status' => 1))->order_by('name', 'ASC')->get('product_categories')->result() as $c)
			$cats[] = array('id' => (int) $c->id, 'name' => $c->name, 'slug' => $c->slug, 'image' => $this->img($c->image));

		$featured = array();
		foreach ($this->db->where('is_active', 1)->order_by('id', 'DESC')->limit(10)->get('productss')->result() as $p)
			$featured[] = $this->product_row($p);

		$this->ok(array('sliders' => $sliders, 'categories' => $cats, 'featured' => $featured));
	}

	/** All active categories (flat; app builds the tree with parent_id) */
	public function categories()
	{
		$out = array();
		foreach ($this->db->where('status', 1)->order_by('parent_id ASC, name ASC')->get('product_categories')->result() as $c)
			$out[] = array('id' => (int) $c->id, 'name' => $c->name, 'slug' => $c->slug,
				'parent_id' => $c->parent_id ? (int) $c->parent_id : 0, 'level' => (int) $c->level, 'image' => $this->img($c->image));
		$this->ok(array('data' => $out));
	}

	/** Product list: ?cat_id= &sub_cat_id= &q= &sort=new|price_low|price_high &page= &per_page= */
	public function products()
	{
		$page     = max(1, (int) $this->input->get('page'));
		$per_page = min(50, max(1, (int) $this->input->get('per_page') ?: 20));
		$offset   = ($page - 1) * $per_page;
		$q        = trim((string) $this->input->get('q'));
		$cat_id   = (int) $this->input->get('cat_id');
		$sub_id   = (int) $this->input->get('sub_cat_id');

		$this->db->from('productss')->where('is_active', 1);
		if ($sub_id) $this->db->where('sub_cat_id', $sub_id);
		elseif ($cat_id)
		{
			// include the category itself + all its descendant category ids
			$ids = $this->descendant_ids($cat_id);
			$this->db->group_start()->where('cat_id', $cat_id)->or_where_in('sub_cat_id', $ids)->or_where_in('cat_id', $ids)->group_end();
		}
		if ($q !== '') $this->db->group_start()->like('name', $q)->or_like('sku', $q)->or_like('tags', $q)->or_like('slug', $q)->group_end();

		$total = $this->db->count_all_results('', FALSE);

		switch ((string) $this->input->get('sort'))
		{
			case 'price_low':  $this->db->order_by('price', 'ASC'); break;
			case 'price_high': $this->db->order_by('price', 'DESC'); break;
			default:           $this->db->order_by('id', 'DESC');
		}
		$rows = array();
		foreach ($this->db->limit($per_page, $offset)->get()->result() as $p) $rows[] = $this->product_row($p);

		$this->ok(array('data' => $rows, 'total' => (int) $total, 'page' => $page, 'per_page' => $per_page, 'has_more' => ($offset + count($rows)) < $total));
	}

	private function descendant_ids($parent_id)
	{
		$ids = array((int) $parent_id);
		$stack = array((int) $parent_id);
		while ($stack)
		{
			$pid = array_pop($stack);
			foreach ($this->db->select('id')->where('parent_id', $pid)->get('product_categories')->result() as $c)
				if ( ! in_array((int) $c->id, $ids, TRUE)) { $ids[] = (int) $c->id; $stack[] = (int) $c->id; }
		}
		return $ids;
	}

	/** Single product: ?id= or ?slug= */
	public function product()
	{
		$id = (int) $this->input->get('id');
		$slug = trim((string) $this->input->get('slug'));
		if ($id) $this->db->where('id', $id); elseif ($slug !== '') $this->db->where('slug', $slug); else $this->fail('id or slug required');
		$p = $this->db->where('is_active', 1)->get('productss')->row();
		if ( ! $p) $this->fail('Product not found', 404);

		$related = array();
		foreach ($this->db->where('is_active', 1)->where('cat_id', $p->cat_id)->where('id !=', $p->id)->order_by('id', 'DESC')->limit(8)->get('productss')->result() as $r)
			$related[] = $this->product_row($r);

		$this->ok(array('product' => $this->product_row($p, TRUE), 'related' => $related));
	}

	/* ---------- auth (manage_signup) ---------- */

	public function register()
	{
		$b = $this->body();
		$name   = trim((string) ($b['name'] ?? ''));
		$email  = trim((string) ($b['email'] ?? ''));
		$mobile = trim((string) ($b['mobile'] ?? ''));
		$pass   = (string) ($b['password'] ?? '');
		if ($name === '' || ! filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($pass) < 6)
			$this->fail('Name, valid email and a 6+ char password are required.');
		if ($this->db->where('email', $email)->count_all_results('manage_signup'))
			$this->fail('This email is already registered. Please log in.');

		$c_id = (int) $this->db->select_max('c_id')->get('manage_signup')->row()->c_id + 1;
		$this->db->insert('manage_signup', array(
			'name' => $name, 'email' => $email, 'mobile' => $mobile,
			'password' => password_hash($pass, PASSWORD_BCRYPT), 'is_active' => 1,
			'c_id' => $c_id, 's_date' => date('Y-m-d'), 'hide_side_menu' => '[]',
		));
		$id = $this->db->insert_id();
		$this->ok(array('user' => array('id' => $id, 'c_id' => $c_id, 'name' => $name, 'email' => $email, 'mobile' => $mobile), 'token' => $this->token($id)));
	}

	public function login()
	{
		$b = $this->body();
		$email = trim((string) ($b['email'] ?? ''));
		$pass  = (string) ($b['password'] ?? '');
		$u = $this->db->group_start()->where('email', $email)->or_where('mobile', $email)->group_end()->get('manage_signup')->row();
		if ( ! $u) $this->fail('Account not found. Please register.', 404);
		$okpw = password_verify($pass, $u->password) || ($pass !== '' && $pass === $u->password);
		if ( ! $okpw) $this->fail('Wrong password.', 401);
		if ((int) $u->is_active === 0) $this->fail('Account is disabled.', 403);
		$this->ok(array('user' => array('id' => (int) $u->id, 'c_id' => (int) $u->c_id, 'name' => $u->name, 'email' => $u->email, 'mobile' => $u->mobile), 'token' => $this->token($u->id)));
	}

	private function token($id) { return base64_encode($id.'|'.md5($id.'itb-app-'.date('Ymd'))); }

	/* ---------- orders (app_orders) ---------- */

	/** POST: user_id?, name, mobile, address, pincode?, items:[{product_id, qty}], payment=cod */
	public function place_order()
	{
		$b = $this->body();
		$name    = trim((string) ($b['name'] ?? ''));
		$mobile  = trim((string) ($b['mobile'] ?? ''));
		$address = trim((string) ($b['address'] ?? ''));
		$items   = $b['items'] ?? array();
		if (is_string($items)) $items = json_decode($items, TRUE);
		if ($name === '' || $mobile === '' || $address === '' || ! is_array($items) || ! $items)
			$this->fail('Name, mobile, address and at least one item are required.');

		$order_items = array(); $total = 0;
		foreach ($items as $it)
		{
			$pid = (int) ($it['product_id'] ?? 0);
			$qty = max(1, (int) ($it['qty'] ?? 1));
			$p = $this->db->where('id', $pid)->where('is_active', 1)->get('productss')->row();
			if ( ! $p) continue;
			$line = (float) $p->price * $qty;
			$total += $line;
			$order_items[] = array('product_id' => $pid, 'name' => $p->name, 'price' => (float) $p->price, 'qty' => $qty, 'line_total' => $line, 'image' => $p->image);
		}
		if ( ! $order_items) $this->fail('No valid products in the order.');

		$this->db->insert('app_orders', array(
			'user_id'  => (int) ($b['user_id'] ?? 0) ?: NULL,
			'name'     => $name, 'mobile' => $mobile, 'address' => $address,
			'pincode'  => trim((string) ($b['pincode'] ?? '')),
			'total'    => $total, 'payment' => 'cod', 'status' => 'pending',
			'created_at' => date('Y-m-d H:i:s'),
		));
		$oid = $this->db->insert_id();
		foreach ($order_items as $oi) { $oi['order_id'] = $oid; $this->db->insert('app_order_items', $oi); }

		$this->ok(array('order_id' => $oid, 'total' => $total, 'message' => 'Order placed. Our team will call you to confirm.'));
	}

	/** GET: ?user_id= — that user's app orders */
	public function orders()
	{
		$uid = (int) $this->input->get('user_id');
		if ( ! $uid) $this->fail('user_id required');
		$out = array();
		foreach ($this->db->where('user_id', $uid)->order_by('id', 'DESC')->get('app_orders')->result() as $o)
		{
			$items = array();
			foreach ($this->db->where('order_id', $o->id)->get('app_order_items')->result() as $i)
				$items[] = array('name' => $i->name, 'price' => (float) $i->price, 'qty' => (int) $i->qty, 'image' => $this->img($i->image));
			$out[] = array('order_id' => (int) $o->id, 'total' => (float) $o->total, 'status' => $o->status,
				'created_at' => $o->created_at, 'items' => $items);
		}
		$this->ok(array('data' => $out));
	}

	/* ---------- one-time table setup ---------- */

	private function ensure_tables()
	{
		if ( ! $this->db->table_exists('app_orders'))
			$this->db->query("CREATE TABLE app_orders (
				id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, user_id INT NULL, name VARCHAR(150) NOT NULL, mobile VARCHAR(30) NOT NULL,
				address TEXT NOT NULL, pincode VARCHAR(12) NULL, total DECIMAL(12,2) NOT NULL DEFAULT 0, payment VARCHAR(20) NOT NULL DEFAULT 'cod',
				status VARCHAR(20) NOT NULL DEFAULT 'pending', created_at DATETIME NOT NULL, KEY idx_user (user_id)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
		if ( ! $this->db->table_exists('app_order_items'))
			$this->db->query("CREATE TABLE app_order_items (
				id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, order_id INT NOT NULL, product_id INT NOT NULL, name VARCHAR(255) NOT NULL,
				price DECIMAL(12,2) NOT NULL DEFAULT 0, qty INT NOT NULL DEFAULT 1, line_total DECIMAL(12,2) NOT NULL DEFAULT 0,
				image VARCHAR(255) NULL, KEY idx_order (order_id)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
	}
}
