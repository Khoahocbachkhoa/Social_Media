import api from "./client";

// register
export const registerApi = (userData) => {
  return api.post("/auth/register", userData);
};

// login
export const loginApi = (userData) => {
  return api.post("/auth/login", userData);
};

// get current user info
export const getMeApi = () => {
  return api.get("/auth/me");
};
