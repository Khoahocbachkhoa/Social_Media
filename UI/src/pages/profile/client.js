import axios from "axios";

// sau này thì import từ env vào
export const api = axios.create({
  baseURL:  "http://localhost:8000/api",
  headers: {
    "Content-Type": "application/json",
  }
});

// Gắn Token vào mỗi request
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem(TOKEN_KEY);
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error) // nếu có error thì trả về Promise để xử lý trong hàm xử lý bất đồng bộ
)

// Xử lý khi token hết hạn hoặc không hợp lệ
api.interceptors.response.use(
  (response) => response,
  (error) => {
    // Đưa người dùng trở lại trang đăng nhập nếu token không hợp lệ
    if (error.response?.status === 401) {
      localStorage.removeItem(TOKEN_KEY);
      if (window.location.pathname !== "/login") {
        window.location.href = "/login";
      }
    }
    return Promise.reject(error);
  }
)

