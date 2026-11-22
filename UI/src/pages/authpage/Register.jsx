import React, { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { registerApi } from "../../services/auth";
import styles from "./auth.module.css";

export default function Register() {
  const [form, setForm] = useState({
    full_name: "",
    username: "",
    email: "",
    password: "",
  });

  const [alert, setAlert] = useState({ message: "", type: "" });
  const [loading, setLoading] = useState(false);

  const navigate = useNavigate();

  // Cập nhật giá trị form
  const update = (field) => (event) => {
    setForm((current) => ({
      ...current,
      [field]: event.target.value,
    }));
  };

  // Xử lý đăng ký
  const handleSubmit = async (e) => {
    e.preventDefault();

    const userData = {
      full_name: form.full_name.trim(),
      username: form.username.trim(),
      email: form.email.trim(),
      password: form.password,
    };

    try {
      setLoading(true);
      setAlert({ message: "", type: "" });

      await registerApi(userData);

      setAlert({
        message: "Đăng ký thành công! Đang chuyển sang trang đăng nhập...",
        type: "success",
      });

      setTimeout(() => navigate("/login"), 1000);

    } catch (error) {
      const message =
        error.response?.data?.message ||
        "Đăng ký thất bại. Vui lòng thử lại.";

      setAlert({
        message,
        type: "error",
      });

    } finally {
      setLoading(false);
    }
  };

  return (
    <main className={styles.authPage}>
      <div className={styles["auth-container"]}>
        <div className={styles["auth-header"]}>
          <h1>Social Media App</h1>
          <p>Tạo tài khoản mới</p>
        </div>

        {alert.message && (
          <div
            className={`${styles["alert-message"]} ${styles.alertVisible} ${
              alert.type === "success"
                ? styles["alert-success"]
                : styles["alert-error"]
            }`}
            role="alert"
          >
            {alert.message}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className={styles["form-group"]}>
            <label htmlFor="full_name">Họ và tên</label>
            <input
              id="full_name"
              value={form.full_name}
              onChange={update("full_name")}
              placeholder="Ví dụ: Nguyễn Văn A"
              required
            />
          </div>

          <div className={styles["form-group"]}>
            <label htmlFor="username">Tên người dùng (Username)</label>
            <input
              id="username"
              value={form.username}
              onChange={update("username")}
              placeholder="Ví dụ: nguyenvana"
              required
            />
          </div>

          <div className={styles["form-group"]}>
            <label htmlFor="email">Địa chỉ Email</label>
            <input
              id="email"
              type="email"
              value={form.email}
              onChange={update("email")}
              placeholder="name@example.com"
              required
            />
          </div>

          <div className={styles["form-group"]}>
            <label htmlFor="password">Mật khẩu</label>
            <input
              id="password"
              type="password"
              value={form.password}
              onChange={update("password")}
              placeholder="Nhập mật khẩu"
              required
            />
          </div>

          <button
            type="submit"
            className={styles["btn-primary"]}
            disabled={loading}
          >
            {loading ? "Đang đăng ký..." : "Đăng ký"}
          </button>
        </form>

        <div className={styles["auth-footer"]}>
          <p>
            Đã có tài khoản? <Link to="/login">Đăng nhập</Link>
          </p>
        </div>
      </div>
    </main>
  );
}