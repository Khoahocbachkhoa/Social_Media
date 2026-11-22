import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import Login from "./pages/authpage/Login";
import Register from "./pages/authpage/Register";
import Feed from "./pages/feed/Feed";

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/login" replace />} />
        <Route path="/login" element={<Login/>}/>
        <Route path="/register" element={<Register/>}/>
        <Route path="/feed" element={<Feed/>}/>
      </Routes>
    </BrowserRouter>
  )
}

export default App
