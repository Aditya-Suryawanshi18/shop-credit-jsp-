package servlet;

import java.io.*;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.annotation.*;
import javax.servlet.http.*;
import doa.DBConnection;

@WebServlet("/SettleDealerCreditServlet")
public class SettleDealerCreditServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String idStr           = request.getParameter("id");
        String settleAmountStr = request.getParameter("settleAmount");
        String paymentMode     = request.getParameter("paymentMode");

        // ── Validation ──────────────────────────────────────────────────────
        if (idStr == null || settleAmountStr == null) {
            response.sendRedirect("view_dealers.jsp?error=Invalid input");
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
            int    id     = Integer.parseInt(idStr.trim());
            double amount = Double.parseDouble(settleAmountStr.trim());

            if (amount <= 0) {
                response.sendRedirect("settle_credit_dealer.jsp?id=" + id
                        + "&error=Amount must be greater than zero");
                return;
            }

            // ── 1. Deduct credit ─────────────────────────────────────────────
            String sql = "UPDATE dealers SET credit = credit - ? WHERE id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setDouble(1, amount);
            ps.setInt(2, id);
            ps.executeUpdate();
            ps.close();

            // ── 2. Insert transaction record with payment_mode ───────────────
            String txnSql =
                "INSERT INTO dealer_transactions "
              + "  (id, dealer_id, transaction_type, amount, payment_mode) "
              + "VALUES (dealer_txn_seq.NEXTVAL, ?, 'SETTLE', ?, ?)";
            PreparedStatement psTxn = conn.prepareStatement(txnSql);
            psTxn.setInt(1, id);
            psTxn.setDouble(2, amount);
            psTxn.setString(3, paymentMode);
            psTxn.executeUpdate();
            psTxn.close();

            response.sendRedirect("view_dealers.jsp?success=Credit settled successfully ("
                    + paymentMode + ")");

        } catch (NumberFormatException e) {
            response.sendRedirect("view_dealers.jsp?error=Invalid number: " + e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("view_dealers.jsp?error=" + e.getMessage());
        }
    }
}