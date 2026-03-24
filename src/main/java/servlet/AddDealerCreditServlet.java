package servlet;

import java.io.*;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.*;
import javax.servlet.annotation.*;
import javax.servlet.http.*;
import doa.DBConnection;

@WebServlet("/AddDealerCreditServlet")
public class AddDealerCreditServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // ── Simple data holder ────────────────────────────────────────────────────
    private static class LineItem {
        int    productId;
        String productName;
        int    quantity;
        double unitPrice;
        double amount;
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String dealerIdStr = request.getParameter("dealerId");
        String itemsJson   = request.getParameter("itemsJson");

        if (dealerIdStr == null || itemsJson == null || itemsJson.trim().isEmpty()) {
            response.sendRedirect("view_dealers.jsp?error=Invalid input");
            return;
        }

        int dealerId;
        try {
            dealerId = Integer.parseInt(dealerIdStr.trim());
        } catch (NumberFormatException e) {
            response.sendRedirect("view_dealers.jsp?error=Invalid dealer ID");
            return;
        }

        List<LineItem> items;
        try {
            items = parseItems(itemsJson);
        } catch (Exception e) {
            response.sendRedirect("add_credit_dealer.jsp?id=" + dealerId +
                "&error=Could not read items: " + e.getMessage());
            return;
        }

        if (items.isEmpty()) {
            response.sendRedirect("add_credit_dealer.jsp?id=" + dealerId + "&error=No items to save");
            return;
        }

        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            double grandTotal = 0;

            for (LineItem item : items) {

                // ── 1. Verify product exists ──────────────────────────────────
                PreparedStatement psCheck = conn.prepareStatement(
                    "SELECT id FROM products WHERE id = ?");
                psCheck.setInt(1, item.productId);
                ResultSet rsCheck = psCheck.executeQuery();
                if (!rsCheck.next()) {
                    conn.rollback();
                    psCheck.close();
                    response.sendRedirect("add_credit_dealer.jsp?id=" + dealerId +
                        "&error=Product not found: ID " + item.productId);
                    return;
                }
                psCheck.close();

                // ── 2. ADD quantity to stock (dealer supplies goods) ──────────
                PreparedStatement psAdd = conn.prepareStatement(
                    "UPDATE products SET quantity = quantity + ? WHERE id = ?");
                psAdd.setInt(1, item.quantity);
                psAdd.setInt(2, item.productId);
                psAdd.executeUpdate();
                psAdd.close();

                // ── 3. Insert transaction row ─────────────────────────────────
                PreparedStatement psTxn = conn.prepareStatement(
                    "INSERT INTO dealer_transactions " +
                    "  (id, dealer_id, transaction_type, amount, product_name, quantity, unit_price) " +
                    "VALUES (dealer_txn_seq.NEXTVAL, ?, 'ADD', ?, ?, ?, ?)");
                psTxn.setInt(1, dealerId);
                psTxn.setDouble(2, item.amount);
                psTxn.setString(3, item.productName.trim());
                psTxn.setInt(4, item.quantity);
                psTxn.setDouble(5, item.unitPrice);
                psTxn.executeUpdate();
                psTxn.close();

                grandTotal += item.amount;
            }

            // ── 4. Update dealer credit (grand total) ─────────────────────────
            PreparedStatement psCredit = conn.prepareStatement(
                "UPDATE dealers SET credit = credit + ? WHERE id = ?");
            psCredit.setDouble(1, grandTotal);
            psCredit.setInt(2, dealerId);
            psCredit.executeUpdate();
            psCredit.close();

            conn.commit();
            response.sendRedirect("view_dealers.jsp?success=Credit added and stock updated (" +
                items.size() + " item" + (items.size() > 1 ? "s" : "") +
                ", total Rs." + String.format("%.2f", grandTotal) + ")");

        } catch (Exception e) {
            try { if (conn != null) conn.rollback(); } catch (Exception ignored) {}
            e.printStackTrace();
            response.sendRedirect("add_credit_dealer.jsp?id=" + dealerId +
                "&error=" + e.getMessage());
        } finally {
            try { if (conn != null) conn.setAutoCommit(true); } catch (Exception ignored) {}
        }
    }

    // ── Minimal JSON array parser (no external dependencies) ──────────────────
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

    /** Split a sequence of {...} objects at the top level. */
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

    /** Extract the raw value for a key from a flat JSON object string. */
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