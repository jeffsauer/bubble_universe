import gg
import math

const window_width = 800
const window_height = 600
const n = 200
const tau = math.pi * 2
const r = tau / 235.0
const sz = 90.0

struct App {
mut:
	gg         &gg.Context = unsafe { nil }
	t          f64
	img_idx    int // We track the streaming image index
	raw_pixels []u32
}

fn main() {
	mut app := &App{
		t:          0.0
		img_idx:    -1
		raw_pixels: []u32{len: window_width * window_height}
	}

	app.gg = gg.new_context(
		width: window_width
		height: window_height
		window_title: 'Bubble Universe'
		frame_fn: frame
		init_fn: init
		user_data: app
	)

	app.gg.run()
}

fn init(mut app App) {
	// Dynamically create a dynamic stream buffer in VRAM without looking for a file path
	app.img_idx = app.gg.new_streaming_image(window_width, window_height, 4, gg.StreamingImageConfig{
		pixel_format: .rgba8
		mag_filter: .nearest
	})
}

fn frame(mut app App) {
	app.gg.begin()

	sw := f64(window_width) / 2.0
	sh := f64(window_height) / 2.0

	mut x := 0.0
	mut v := 0.0

	// Wipe the frame buffer black instantly 
	unsafe {
		C.memset(app.raw_pixels.data, 0, window_width * window_height * sizeof(u32))
	}

	for i := 0; i <= n; i++ {
		for j := 0; j <= n; j++ {
			fi := f64(i)
			
			u := math.sin(fi + v) + math.sin(r * fi + x)
			v = math.cos(fi + v) + math.cos(r * fi + x)
			x = u + app.t

			// Map structural color bytes
			r_col := u32((fi / f64(n)) * 255)
			g_col := u32((f64(j) / f64(n)) * 255)
			b_col := u32(220)
			a_col := u32(255)

			// Package standard RGBA integer
			rgba_color := (a_col << 24) | (b_col << 16) | (g_col << 8) | r_col

			// Shift coordinates to screen center
			plot_x := int(u * sz + sw)
			plot_y := int(v * sz + sh)

			// Enforce boundaries
			if plot_x >= 0 && plot_x < window_width && plot_y >= 0 && plot_y < window_height {
				pixel_index := plot_y * window_width + plot_x
				app.raw_pixels[pixel_index] = rgba_color
			}
		}
	}

	// Update the pixel cache payload via the index
	app.gg.update_pixel_data(app.img_idx, unsafe { &u8(app.raw_pixels.data) })

	// Grab the reference representation from memory cache and draw
	img := app.gg.get_cached_image_by_idx(app.img_idx)
	app.gg.draw_image(0, 0, window_width, window_height, img)

	app.t += 1.0 / f64(n)
	app.gg.end()
}

