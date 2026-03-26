package servlet;

import java.io.*;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.annotation.*;
import javax.servlet.http.*;
import doa.DBConnection;

@WebServlet("/AddDealerServlet")
public class AddDealerServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String name        = request.getParameter("name");
        String marathiName = request.getParameter("marathiName"); // optional
        String phone       = request.getParameter("phone");
        String creditStr   = request.getParameter("credit");
        String address     = request.getParameter("address");

        // Sanitise optional Marathi name
        if (marathiName != null && marathiName.trim().isEmpty()) marathiName = null;
        if (marathiName != null) marathiName = marathiName.trim();

        if (name == null || phone == null || creditStr == null || address == null ||
                name.isEmpty() || phone.isEmpty() || creditStr.isEmpty() || address.isEmpty()) {
            response.sendRedirect("add_dealer.jsp?error=Please fill all required fields");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            String sql = "INSERT INTO dealers (id, name, marathi_name, phone, credit, address) "
                       + "VALUES (dealer_seq.NEXTVAL, ?, ?, ?, ?, ?)";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, name.trim());
            ps.setString(2, marathiName);       // NULL if not provided
            ps.setString(3, phone.trim());
            ps.setDouble(4, Double.parseDouble(creditStr));
            ps.setString(5, address.trim());
            ps.executeUpdate();

            response.sendRedirect("view_dealers.jsp?success=Dealer added successfully");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("view_dealers.jsp?error=" + e.getMessage());
        }
    }
}
