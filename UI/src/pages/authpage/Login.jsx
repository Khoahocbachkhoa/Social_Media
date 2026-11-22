import React, { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { loginApi } from "../../services/auth";
import { TOKEN_KEY } from "../../services/client";
import styles from "./auth.module.css";

export default function Login() {
  const [account, setAccount] = useState("");
  const [password, setPassword] = useState("");
  const [alert, setAlert] = useState({ message: "", type: "" });
  const [loading, setLoading] = useState(false);

  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();

    try {
      setLoading(true);
      setAlert({ message: "", type: "" });

      const response = await loginApi({
        account: account.trim(),
        password,
      });

      const data = response.data;

      localStorage.setItem(TOKEN_KEY, data.token);
      localStorage.setItem("user", JSON.stringify(data.user));

      setAlert({
        message: "Đăng nhập thành công! Đang chuyển hướng...",
        type: "success",
      });

      setTimeout(() => navigate("/feed"), 1000);

    } catch (error) {
      const message =
        error.response?.data?.message ||
        "Đăng nhập thất bại. Vui lòng thử lại";

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
          <p>Kết nối và chia sẻ khoảnh khắc</p>
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

        <form onSubmit={handleLogin}>
          <div className={styles["form-group"]}>
            <label htmlFor="account">Tài khoản</label>
            <input
              id="account"
              type="text"
              value={account}
              onChange={(e) => setAccount(e.target.value)}
              placeholder="Username hoặc Email"
              required
            />
          </div>

          <div className={styles["form-group"]}>
            <label htmlFor="password">Mật khẩu</label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Mật khẩu"
              required
            />
          </div>

          <button
            type="submit"
            className={styles["btn-primary"]}
            disabled={loading}
          >
            {loading ? "Đang đăng nhập..." : "Đăng nhập"}
          </button>
        </form>

        <div className={styles["auth-footer"]}>
          <p>
            Chưa có tài khoản? <Link to="/register">Đăng ký ngay</Link>
          </p>
        </div>
      </div>
    </main>
  );
}