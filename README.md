# PetJoy - Pet Shop Flutter

PetJoy là ứng dụng pet shop local-first viết bằng Flutter. Ứng dụng dùng Drift làm database chính trên thiết bị, Riverpod quản lý state, SharedPreferences lưu session nhẹ, Firebase Auth xử lý đăng nhập/xác minh email và Cloudinary lưu ảnh.

## Công nghệ

- Flutter Material 3
- Riverpod cho dependency injection và state
- Drift + SQLite cho dữ liệu local
- SharedPreferences cho `currentUserId` và trạng thái đã xem màn chào mừng
- Firebase Auth cho email/password, Google Sign-In và email verification link
- Cloudinary cho upload/get ảnh

## Flow dữ liệu trong app

Khi mở app, `SplashScreen` gọi `AuthRepository.restoreSession()`. Repository reload Firebase user hiện tại, đồng bộ user về bảng `local_users`, lưu `currentUserId` trong SharedPreferences rồi chuyển sang màn phù hợp.

Khi đăng ký email/password, app tạo tài khoản trên Firebase Auth, lưu user vào Drift với `passwordHash` đã salted hash bằng SHA-256, sau đó gửi email xác minh bằng Firebase Auth. User được chuyển sang màn chờ xác thực.

Khi đăng nhập email/password, Firebase Auth xác thực credential. Nếu email chưa xác minh, app chuyển sang màn chờ xác thực. Nếu đã xác minh, app vào home.

Drift là nguồn dữ liệu nghiệp vụ chính cho user local, danh mục, sản phẩm, giỏ hàng, wishlist, đơn hàng và thông báo. App không dùng Firestore và không gọi API backend cho dữ liệu shop.

Ảnh banner/onboarding/sản phẩm được lưu trên Cloudinary. URL ảnh được lưu vào Drift, ví dụ `products.thumbnail`.

## Cloudinary đã cấu hình

- Folder banner: `pet_shop/banners`
- Folder sản phẩm: `pet_shop/products`
- Folder onboarding: `pet_shop/onboarding`

## Màn hình đã triển khai

- Splash screen PetJoy
- Đăng nhập email/password
- Đăng nhập Google
- Đăng ký tài khoản
- Chờ xác thực email bằng Firebase Auth link
- Chào mừng đến với gia đình Pet Shop
- Home: search, banner, danh mục, sản phẩm nổi bật, bottom navigation

## Lệnh phát triển

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

## Tài liệu cấu hình

Xem [docs/firebase_setup_vi.md](docs/firebase_setup_vi.md).
