package servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import doa.DBConnection;

@WebServlet("/CashSaleServlet")
public class CashSaleServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private static class LineItem {
        int    productId;
        String productName;
        int    quantity;
        double unitPrice;
        double amount;
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String customerIdStr = request.getParameter("customerId");
        String itemsJson     = request.getParameter("itemsJson");
        String paymentMode   = request.getParameter("paymentMode");

        // Default / sanitise payment mode
        if (paymentMode == null || paymentMode.trim().isEmpty()) paymentMode = "CASH";
        if (!paymentMode.equals("CASH") && !paymentMode.equals("ONLINE")) paymentMode = "CASH";

        if (customerIdStr == null || itemsJson == null || itemsJson.trim().isEmpty()) {
            response.sendRedirect("cash_sale.jsp?error=Invalid input");
            return;
        }

        int customerId;
        try {
            customerId = Integer.parseInt(customerIdStr.trim());
        } catch (NumberFormatException e) {
            response.sendRedirect("cash_sale.jsp?error=Invalid customer ID");
            return;
        }

        List<LineItem> items;
        try {
            items = parseItems(itemsJson);
        } catch (Exception e) {
            response.sendRedirect("cash_sale.jsp?id=" + customerId +
                "&error=Could not read items: " + e.getMessage());
            return;
        }

        if (items.isEmpty()) {
            response.sendRedirect("cash_sale.jsp?id=" + customerId + "&error=No items to save");
            return;
        }

        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            double grandTotal = 0;
            final String pm   = paymentMode;

            for (LineItem item : items) {

                // ── 1. Check stock ────────────────────────────────────────────
                PreparedStatement psStock = conn.prepareStatement(
                    "SELECT quantity FROM products WHERE id = ?");
                psStock.setInt(1, item.productId);
                ResultSet rsStock = psStock.executeQuery();

                if (!rsStock.next()) {
                    conn.rollback();
                    psStock.close();
                    response.sendRedirect("cash_sale.jsp?id=" + customerId +
                        "&error=Product not found: ID " + item.productId);
                    return;
                }
                int availableStock = rsStock.getInt("quantity");
                psStock.close();

                if (availableStock < item.quantity) {
                    conn.rollback();
                    response.sendRedirect("cash_sale.jsp?id=" + customerId +
                        "&error=Insufficient stock for " + item.productName +
                        ". Available: " + availableStock);
                    return;
                }

                // ── 2. Deduct stock ───────────────────────────────────────────
                PreparedStatement psDeduct = conn.prepareStatement(
                    "UPDATE products SET quantity = quantity - ? WHERE id = ?");
                psDeduct.setInt(1, item.quantity);
                psDeduct.setInt(2, item.productId);
                psDeduct.executeUpdate();
                psDeduct.close();

                // ── 3. Insert transaction row (type = CASH_SALE) ──────────────
                //       Reuses customer_transactions table with new type value.
                //       payment_mode stores CASH / ONLINE.
                //       credit column is NOT touched — no debt created.
                PreparedStatement psTxn = conn.prepareStatement(
                    "INSERT INTO customer_transactions " +
                    "  (id, customer_id, transaction_type, amount, " +
                    "   product_name, quantity, unit_price, payment_mode) " +
                    "VALUES (customer_txn_seq.NEXTVAL, ?, 'CASH_SALE', ?, ?, ?, ?, ?)");
                psTxn.setInt(1, customerId);
                psTxn.setDouble(2, item.amount);
                psTxn.setString(3, item.productName.trim());
                psTxn.setInt(4, item.quantity);
                psTxn.setDouble(5, item.unitPrice);
                psTxn.setString(6, pm);
                psTxn.executeUpdate();
                psTxn.close();

                grandTotal += item.amount;
            }

            // ── NOTE: credit balance is NOT updated — this is a cash sale ────
            conn.commit();

            response.sendRedirect("view_customers.jsp?success=Cash sale recorded (" +
                items.size() + " item" + (items.size() > 1 ? "s" : "") +
                ", total Rs." + String.format("%.2f", grandTotal) + ", " + paymentMode + ")");

        } catch (Exception e) {
            try { if (conn != null) conn.rollback(); } catch (Exception ignored) {}
            e.printStackTrace();
            response.sendRedirect("cash_sale.jsp?id=" + customerId + "&error=" + e.getMessage());
        } finally {
            try { if (conn != null) conn.setAutoCommit(true); } catch (Exception ignored) {}
        }
    }

    // ── Minimal JSON array parser (same as AddCreditServlet) ─────────────────
    private List<LineItem> parseItems(String json) throws Exception {
        List<LineItem> list = new ArrayList<>();
        json = json.trim();
        if (json.startsWith("[")) json = json.substring(1);
        if (json.endsWith("]"))   json = json.substring(0, json.length() - 1);
        json = json.trim();
        if (json.isEmpty()) return list;

        for (String obj : splitObjects(json)) {
            LineItem item = new LineItem();
            item.productId   = Integer.parseInt(extractValue(obj, "productId"));
            item.productName = extractValue(obj, "productName");
            item.quantity    = Integer.parseInt(extractValue(obj, "quantity"));
            item.unitPrice   = Double.parseDouble(extractValue(obj, "unitPrice"));
            item.amount      = Double.parseDouble(extractValue(obj, "amount"));
            list.add(item);
        }
        return list;
    }

    private List<String> splitObjects(String json) {
        List<String> result = new ArrayList<>();
        int depth = 0, start = 0;
        boolean inString = false;
        for (int i = 0; i < json.length(); i++) {
            char c = json.charAt(i);
            if (c == '"' && (i == 0 || json.charAt(i - 1) != '\\')) inString = !inString;
            if (inString) continue;
            if (c == '{') { if (depth == 0) start = i; depth++; }
            else if (c == '}') { depth--; if (depth == 0) result.add(json.substring(start, i + 1)); }
        }
        return result;
    }

    private String extractValue(String obj, String key) throws Exception {
        String search = "\"" + key + "\"";
        int idx = obj.indexOf(search);
        if (idx < 0) throw new Exception("Key not found: " + key);
        int colon = obj.indexOf(':', idx + search.length());
        if (colon < 0) throw new Exception("Malformed JSON near: " + key);
        int s = colon + 1;
        while (s < obj.length() && obj.charAt(s) == ' ') s++;
        if (obj.charAt(s) == '"') {
            int e = s + 1;
            while (e < obj.length() && !(obj.charAt(e) == '"' && obj.charAt(e - 1) != '\\')) e++;
            return obj.substring(s + 1, e);
        } else {
            int e = s;
            while (e < obj.length() && obj.charAt(e) != ',' && obj.charAt(e) != '}') e++;
            return obj.substring(s, e).trim();
        }
    }
}
