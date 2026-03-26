package servlet;

import java.io.*;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.annotation.*;
import javax.servlet.http.*;
import doa.DBConnection;

@WebServlet("/AddProductServlet")
public class AddProductServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String productName   = request.getParameter("productName");
        String marathiName   = request.getParameter("marathiName"); // optional
        String quantityStr   = request.getParameter("quantity");

        if (productName == null || productName.trim().isEmpty()
                || quantityStr == null || quantityStr.trim().isEmpty()) {
            response.sendRedirect("view_products.jsp?error=Please fill all fields");
            return;
        }

        // Sanitise optional Marathi name
        if (marathiName != null && marathiName.trim().isEmpty()) marathiName = null;
        if (marathiName != null) marathiName = marathiName.trim();

        try (Connection conn = DBConnection.getConnection()) {
            int quantity = Integer.parseInt(quantityStr.trim());

            String sql = "INSERT INTO products (id, product_name, marathi_name, quantity) "
                       + "VALUES (product_seq.NEXTVAL, ?, ?, ?)";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, productName.trim());
            ps.setString(2, marathiName);   // NULL if not provided
            ps.setInt(3, quantity);
            ps.executeUpdate();

            response.sendRedirect("view_products.jsp?success=Product added successfully");
        } catch (NumberFormatException e) {
            response.sendRedirect("view_products.jsp?error=Invalid quantity value");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("view_products.jsp?error=" + e.getMessage());
        }
    }
}
