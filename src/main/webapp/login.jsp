<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    if (session.getAttribute("admin") != null) {
        response.sendRedirect("main.jsp");
        return;
    }
    String errorMsg  = request.getParameter("error");
    String logoutMsg = request.getParameter("logout");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login — Mauali Tredars</title>
    <link rel="stylesheet" href="css/login.css">
</head>
<body>
<div class="login-container">

    <!-- Brand -->
    <div class="brand-section">
        <span class="brand-icon">🏪</span>
        <div class="brand-title">Mauali Tredars</div>
        <div class="brand-sub">Shop Credit Management System</div>
    </div>

    <!-- Card -->
    <div class="login-card">
        <h2>Welcome back</h2>

        <% if (errorMsg != null) { %>
        <div class="error-msg">❌ <%= errorMsg %></div>
        <% } %>
        <% if (logoutMsg != null) { %>
        <div class="error-msg success">✅ You've been signed out successfully.</div>
        <% } %>

        <form action="LoginServlet" method="post" autocomplete="off">

            <div class="field-group">
                <label for="username">Username</label>
                <input type="text" id="username" name="username"
                       placeholder="Enter your username" required autofocus>
            </div>

            <div class="field-group">
                <label for="password">Password</label>
                <div class="pwd-wrapper">
                    <input type="password" id="password" name="password"
                           placeholder="Enter your password" required>
                    <button type="button" class="eye-btn" onclick="togglePassword()" title="Show / Hide">
                        <svg id="iconEyeOpen" width="18" height="18" viewBox="0 0 24 24"
                             fill="none" stroke="currentColor" stroke-width="2"
                             stroke-linecap="round" stroke-linejoin="round">
                            <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                            <circle cx="12" cy="12" r="3"/>
                        </svg>
                        <svg id="iconEyeClosed" width="18" height="18" viewBox="0 0 24 24"
                             fill="none" stroke="currentColor" stroke-width="2"
                             stroke-linecap="round" stroke-linejoin="round"
                             style="display:none;">
                            <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8
                                     a18.45 18.45 0 0 1 5.06-5.94"/>
                            <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8
                                     a18.5 18.5 0 0 1-2.16 3.19"/>
                            <line x1="1" y1="1" x2="23" y2="23"/>
                        </svg>
                    </button>
                </div>
            </div>

            <button type="submit" class="btn-login">Sign In →</button>
        </form>
    </div>

    <div class="login-footer">© 2025 Mauali Tredars · All rights reserved.</div>
</div>

<script>
function togglePassword() {
    var inp    = document.getElementById('password');
    var open   = document.getElementById('iconEyeOpen');
    var closed = document.getElementById('iconEyeClosed');
    if (inp.type === 'password') {
        inp.type = 'text';
        open.style.display   = 'none';
        closed.style.display = 'block';
    } else {
        inp.type = 'password';
        open.style.display   = 'block';
        closed.style.display = 'none';
    }
}
</script>
</body>
</html>
