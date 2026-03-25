<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, doa.DBConnection" %>
<%
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=Please login first");
        return;
    }
    String keyword = request.getParameter("keyword");
    boolean hasKeyword = (keyword != null && !keyword.trim().isEmpty());
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Products</title>
    <link rel="stylesheet" href="css/content.css">
    <style>
        /* Quick-add inline panel */
        .quick-add-panel {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-top: 3px solid #0d1b2a;
            border-radius: 14px;
            padding: 18px 20px;
            margin-bottom: 16px;
            display: flex;
            align-items: flex-end;
            gap: 14px;
            flex-wrap: wrap;
            box-shadow: 0 1px 4px rgba(0,0,0,0.06);
        }
        .qa-title {
            font-size: 14px; font-weight: 700;
            color: #0d1b2a; text-transform: uppercase;
            letter-spacing: 0.8px; align-self: center;
            white-space: nowrap;
        }
        .qa-group { display: flex; flex-direction: column; gap: 5px; flex: 1; min-width: 160px; }
        .qa-group label { font-size: 11px; font-weight: 700; color: #4a5568; text-transform: uppercase; letter-spacing: 0.6px; }
        .qa-group input {
            padding: 9px 12px;
            border: 1.5px solid #e2e8f0;
            border-radius: 8px;
            font-family: 'Outfit', sans-serif;
            font-size: 13.5px;
            color: #0d1b2a;
            background: #f8fafc;
            outline: none;
            transition: border 0.18s, box-shadow 0.18s;
            -moz-appearance: textfield;
        }
        .qa-group input::-webkit-inner-spin-button,
        .qa-group input::-webkit-outer-spin-button { -webkit-appearance: none; }
        .qa-group input:focus {
            border-color: #0d1b2a;
            background: #fff;
            box-shadow: 0 0 0 3px rgba(13,27,42,0.07);
        }

        /* Stock badges */
        .stock-badge {
            display: inline-flex; align-items: center; gap: 5px;
            padding: 4px 12px; border-radius: 20px;
            font-size: 12px; font-weight: 700;
            font-variant-numeric: tabular-nums;
        }
        .stock-ok   { background: rgba(0,184,122,0.10); color: #00805a; border: 1px solid rgba(0,184,122,0.2); }
        .stock-low  { background: rgba(240,165,0,0.10); color: #a16207; border: 1px solid rgba(240,165,0,0.2); }
        .stock-zero { background: rgba(255,71,87,0.10); color: #be123c; border: 1px solid rgba(255,71,87,0.2); }

        .btn-delete {
            padding: 5px 14px;
            background: rgba(255,71,87,0.08);
            color: #dc2626;
            border: 1px solid rgba(255,71,87,0.2);
            border-radius: 7px;
            font-family: 'Outfit', sans-serif;
            font-size: 12px; font-weight: 600;
            cursor: pointer;
            transition: all 0.18s;
        }
        .btn-delete:hover { background: #ff4757; color: #fff; border-color: #ff4757; }

        .product-id {
            font-size: 12px; font-weight: 700;
            color: #94a3b8; letter-spacing: 0.5px;
        }
    </style>
</head>
<body>
<div class="content-wrapper">

    <% if (request.getParameter("success") != null) { %>
    <div class="alert alert-success">✅ <%= request.getParameter("success") %></div>
    <% } %>
    <% if (request.getParameter("error") != null) { %>
    <div class="alert alert-error">❌ <%= request.getParameter("error") %></div>
    <% } %>

    <!-- Quick Add -->
    <form action="AddProductServlet" method="post" onsubmit="return validateProduct()">
        <div class="quick-add-panel">
            <span class="qa-title">New Product</span>
            <div class="qa-group">
                <label for="productName">Product Name</label>
                <input type="text" id="productName" name="productName"
                       placeholder="Enter product name" maxlength="150" required>
            </div>
            <div class="qa-group" style="max-width:160px;">
                <label for="quantity">Initial Stock</label>
                <input type="number" id="quantity" name="quantity"
                       placeholder="0" min="0" required>
            </div>
            <button type="submit" class="btn-save" style="padding:10px 24px; font-size:13.5px; white-space:nowrap;">
                💾 Add Product
            </button>
        </div>
    </form>

    <!-- Search -->
    <form class="search-bar" action="view_products.jsp" method="get">
        <input type="text" name="keyword" placeholder="Search by product name or ID…"
               value="<%= hasKeyword ? keyword : "" %>">
        <button type="submit" class="btn-search">🔍 Search</button>
        <a href="view_products.jsp" class="btn-reset">Reset</a>
    </form>

    <!-- Table -->
    <div class="table-container">
        <table>
            <thead>
                <tr>
                    <th style="width:48px;">Sr.No</th>
                    <th style="width:100px;">Product ID</th>
                    <th style="text-align:center;">Product Name</th>
                    <th>Stock Status</th>
                    <th style="width:100px;">Remove</th>
                </tr>
            </thead>
            <tbody>
            <%
                String sql = "SELECT * FROM products";
                if (hasKeyword) sql += " WHERE LOWER(product_name) LIKE ? OR id = ?";
                sql += " ORDER BY id ASC";

                try (Connection conn = DBConnection.getConnection();
                     PreparedStatement ps = conn.prepareStatement(sql)) {

                    if (hasKeyword) {
                        ps.setString(1, "%" + keyword.toLowerCase() + "%");
                        try { ps.setInt(2, Integer.parseInt(keyword)); }
                        catch (NumberFormatException ex) { ps.setInt(2, -1); }
                    }

                    ResultSet rs = ps.executeQuery();
                    boolean hasData = false; int sNo = 1;

                    while (rs.next()) {
                        hasData = true;
                        int    id    = rs.getInt("id");
                        String pname = rs.getString("product_name");
                        int    qty   = rs.getInt("quantity");
                        String cls   = qty == 0 ? "stock-zero" : (qty <= 10 ? "stock-low" : "stock-ok");
                        String icon  = qty == 0 ? "🔴" : (qty <= 10 ? "🟡" : "🟢");
                        String lbl   = qty == 0 ? "Out of Stock" : (qty <= 10 ? "Low: " + qty : "" + qty + " units");
            %>
                <tr>
                    <td style="color:#cbd5e1; font-size:12px;"><%= sNo++ %></td>
                    <td><span class="product-id">P-<%= String.format("%04d",id) %></span></td>
                    <td style="text-align:left;">
                        <div style="text-align: center; align-items:center; gap:8px;">
                            <span style="font-size:16px;">📦</span>
                            <strong style="color:#0d1b2a;"><%= pname %></strong>
                        </div>
                    </td>
                    <td>
                        <span class="stock-badge <%= cls %>">
                            <%= icon %> <%= lbl %>
                        </span>
                    </td>
                    <td>
                        <form action="DeleteProductServlet" method="post" style="display:inline;"
                              onsubmit="return confirm('Delete product: <%= pname %>?')">
                            <input type="hidden" name="id" value="<%= id %>">
                            <button type="submit" class="btn-delete">🗑 Delete</button>
                        </form>
                    </td>
                </tr>
            <%
                    }
                    if (!hasData) {
            %>
                <tr><td colspan="5" class="no-data">No products found. Add your first product above.</td></tr>
            <%
                    }
                } catch (Exception e) {
            %>
                <tr><td colspan="5" class="no-data">❌ Error: <%= e.getMessage() %></td></tr>
            <%
                }
            %>
            </tbody>
        </table>
    </div>

    <!-- Summary Stats -->
    <%
        int totalProducts = 0, inStock = 0, lowStock = 0, outStock = 0;
        try (Connection conn = DBConnection.getConnection()) {
            ResultSet r1 = conn.createStatement().executeQuery("SELECT COUNT(*) FROM products");
            if (r1.next()) totalProducts = r1.getInt(1);
            ResultSet r2 = conn.createStatement().executeQuery("SELECT COUNT(*) FROM products WHERE quantity > 10");
            if (r2.next()) inStock = r2.getInt(1);
            ResultSet r3 = conn.createStatement().executeQuery("SELECT COUNT(*) FROM products WHERE quantity > 0 AND quantity <= 10");
            if (r3.next()) lowStock = r3.getInt(1);
            ResultSet r4 = conn.createStatement().executeQuery("SELECT COUNT(*) FROM products WHERE quantity = 0");
            if (r4.next()) outStock = r4.getInt(1);
        } catch (Exception e) { /* ignore */ }
    %>
    <div class="stats-row" style="margin-top:18px;">
        <div class="stat-chip">
            <div class="s-label">Total Products</div>
            <div class="s-value"><%= totalProducts %></div>
        </div>
        <div class="stat-chip green">
            <div class="s-label">In Stock</div>
            <div class="s-value"><%= inStock %></div>
        </div>
        <div class="stat-chip">
            <div class="s-label">Low Stock</div>
            <div class="s-value" style="color:#d97706;"><%= lowStock %></div>
        </div>
        <div class="stat-chip red">
            <div class="s-label">Out of Stock</div>
            <div class="s-value"><%= outStock %></div>
        </div>
    </div>

</div>

<script>
function validateProduct() {
    var name = document.getElementById('productName').value.trim();
    var qty  = document.getElementById('quantity').value;
    if (!name) { alert('Please enter a product name.'); return false; }
    if (qty === '' || parseInt(qty) < 0) { alert('Please enter a valid quantity.'); return false; }
    return true;
}
</script>
</body>
</html>
