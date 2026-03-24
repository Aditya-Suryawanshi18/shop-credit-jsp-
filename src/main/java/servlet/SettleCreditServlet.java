package servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import doa.DBConnection;

@WebServlet("/SettleCreditServlet")
public class SettleCreditServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String idStr           = request.getParameter("id");
        String settleAmountStr = request.getParameter("settleAmount");
        String paymentMode     = request.getParameter("paymentMode");

        // ── Validation ──────────────────────────────────────────────────────
        if (idStr == null || settleAmountStr == null) {
            response.sendRedirect("view_customers.jsp?error=Invalid input");
            return;
        }

        // Default to CASH if somehow not provided
        if (paymentMode == null || paymentMode.trim().isEmpty()) {
            paymentMode = "CASH";
        }
        // Allow only known values
        if (!paymentMode.equals("CASH") && !paymentMode.equals("ONLINE")) {
            paymentMode = "CASH";
        }

        try (Connection conn = DBConnection.getConnection()) {
            int    id           = Integer.parseInt(idStr.trim());
            double settleAmount = Double.parseDouble(settleAmountStr.trim());

            if (settleAmount <= 0) {
                response.sendRedirect("settle_credit_customer.jsp?id=" + id
                        + "&error=Amount must be greater than zero");
                return;
            }

            // ── 1. Deduct credit (guard: credit must not go negative) ────────
            String sql = "UPDATE customers SET credit = credit - ? "
                       + "WHERE id = ? AND credit >= ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setDouble(1, settleAmount);
            ps.setInt(2, id);
            ps.setDouble(3, settleAmount);

            int updated = ps.executeUpdate();
            ps.close();

            if (updated == 0) {
                response.sendRedirect("settle_credit_customer.jsp?id=" + id
                        + "&error=Insufficient credit to settle");
                return;
            }

            // ── 2. Insert transaction record with payment_mode ───────────────
            String txnSql =
                "INSERT INTO customer_transactions "
              + "  (id, customer_id, transaction_type, amount, payment_mode) "
              + "VALUES (customer_txn_seq.NEXTVAL, ?, 'SETTLE', ?, ?)";
            PreparedStatement psTxn = conn.prepareStatement(txnSql);
            psTxn.setInt(1, id);
            psTxn.setDouble(2, settleAmount);
            psTxn.setString(3, paymentMode);
            psTxn.executeUpdate();
            psTxn.close();

            response.sendRedirect("view_customers.jsp?success=Credit settled successfully ("
                    + paymentMode + ")");

        } catch (NumberFormatException e) {
            response.sendRedirect("view_customers.jsp?error=Invalid number: " + e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("view_customers.jsp?error=" + e.getMessage());
        }
    }
}