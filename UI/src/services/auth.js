import api from "./client";

// register
export const registerApi = (userData) => {
  return api.post('/register', userData);
}

// login
export const loginApi = (userData) => {
  return api.post('/login', userData);
}