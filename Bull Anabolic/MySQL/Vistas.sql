-- Vista de Inventario Detallado
CREATE OR REPLACE VIEW v_inventario_detallado AS
SELECT 
    p.id_producto,
    p.sku,
    p.nombre AS producto,
    c.nombre AS categoria,
    m.nombre AS marca,
    p.precio_venta,
    p.precio_oferta,
    COALESCE(t.nombre, 'N/A') AS talla,
    COALESCE(pt.stock, p.stock) AS stock_disponible,
    p.activo,
    CASE 
        WHEN p.precio_oferta IS NOT NULL THEN 
            ROUND(((p.precio_venta - p.precio_oferta) / p.precio_venta * 100), 2)
        ELSE 0
    END AS porcentaje_descuento
FROM productos p
LEFT JOIN categorias c ON p.id_categoria = c.id_categoria
LEFT JOIN marcas m ON p.id_marca = m.id_marca
LEFT JOIN productos_tallas pt ON p.id_producto = pt.id_producto
LEFT JOIN tallas t ON pt.id_talla = t.id_talla;

-- Vista de Productos Bajo Stock
CREATE OR REPLACE VIEW v_productos_bajo_stock AS
SELECT 
    p.id_producto,
    p.sku,
    p.nombre AS producto,
    c.nombre AS categoria,
    m.nombre AS marca,
    COALESCE(t.nombre, 'N/A') AS talla,
    COALESCE(pt.stock, p.stock) AS stock_actual
FROM productos p
LEFT JOIN categorias c ON p.id_categoria = c.id_categoria
LEFT JOIN marcas m ON p.id_marca = m.id_marca
LEFT JOIN productos_tallas pt ON p.id_producto = pt.id_producto
LEFT JOIN tallas t ON pt.id_talla = t.id_talla
WHERE COALESCE(pt.stock, p.stock) < 5
AND p.activo = 1;

-- Vista de Mejores Productos Vendidos
CREATE OR REPLACE VIEW v_productos_mas_vendidos AS
SELECT 
    p.id_producto,
    p.nombre AS producto,
    c.nombre AS categoria,
    m.nombre AS marca,
    COUNT(DISTINCT dp.id_pedido) AS total_pedidos,
    SUM(dp.cantidad) AS unidades_vendidas,
    SUM(dp.subtotal) AS ingresos_totales,
    ROUND(AVG(v.puntuacion), 2) AS valoracion_promedio
FROM productos p
LEFT JOIN categorias c ON p.id_categoria = c.id_categoria
LEFT JOIN marcas m ON p.id_marca = m.id_marca
LEFT JOIN detalles_pedido dp ON p.id_producto = dp.id_producto
LEFT JOIN valoraciones v ON p.id_producto = v.id_producto
GROUP BY p.id_producto, p.nombre, c.nombre, m.nombre
ORDER BY unidades_vendidas DESC;

-- Vista de Resumen de Pedidos por Cliente
CREATE OR REPLACE VIEW v_resumen_pedidos_cliente AS
SELECT 
    c.id_cliente,
    c.nombre AS cliente,
    c.email,
    COUNT(p.id_pedido) AS total_pedidos,
    SUM(p.total) AS total_gastado,
    MAX(p.fecha_pedido) AS ultima_compra,
    AVG(p.total) AS ticket_promedio
FROM clientes c
LEFT JOIN pedidos p ON c.id_cliente = p.id_cliente
GROUP BY c.id_cliente, c.nombre, c.email;

-- Vista de Valoraciones Detalladas
CREATE OR REPLACE VIEW v_valoraciones_detalladas AS
SELECT 
    v.id_valoracion,
    p.nombre AS producto,
    c.nombre AS cliente,
    v.puntuacion,
    v.comentario,
    v.fecha_valoracion,
    c.email
FROM valoraciones v
JOIN productos p ON v.id_producto = p.id_producto
JOIN clientes c ON v.id_cliente = c.id_cliente
ORDER BY v.fecha_valoracion DESC;

-- Vista de Rendimiento por Categoría
CREATE OR REPLACE VIEW v_rendimiento_categorias AS
SELECT 
    c.nombre AS categoria,
    COUNT(DISTINCT p.id_producto) AS total_productos,
    SUM(COALESCE(pt.stock, p.stock)) AS stock_total,
    COUNT(DISTINCT dp.id_pedido) AS total_ventas,
    SUM(dp.subtotal) AS ingresos_totales,
    ROUND(AVG(v.puntuacion), 2) AS valoracion_promedio
FROM categorias c
LEFT JOIN productos p ON c.id_categoria = p.id_categoria
LEFT JOIN productos_tallas pt ON p.id_producto = pt.id_producto
LEFT JOIN detalles_pedido dp ON p.id_producto = dp.id_producto
LEFT JOIN valoraciones v ON p.id_producto = v.id_producto
GROUP BY c.nombre;

-- Vista de Estado de Pedidos
CREATE OR REPLACE VIEW v_estado_pedidos AS
SELECT 
    p.id_pedido,
    c.nombre AS cliente,
    p.fecha_pedido,
    p.estado_pedido,
    p.total,
    d.ciudad,
    d.estado AS estado_envio,
    p.numero_seguimiento,
    COUNT(dp.id_producto) AS total_productos
FROM pedidos p
JOIN clientes c ON p.id_cliente = c.id_cliente
JOIN direcciones d ON p.id_direccion = d.id_direccion
JOIN detalles_pedido dp ON p.id_pedido = dp.id_pedido
GROUP BY p.id_pedido, c.nombre, p.fecha_pedido, p.estado_pedido, 
         p.total, d.ciudad, d.estado, p.numero_seguimiento;

-- Vista de Productos en Oferta
CREATE OR REPLACE VIEW v_productos_oferta AS
SELECT 
    p.id_producto,
    p.nombre AS producto,
    c.nombre AS categoria,
    m.nombre AS marca,
    p.precio_venta AS precio_regular,
    p.precio_oferta,
    ROUND(((p.precio_venta - p.precio_oferta) / p.precio_venta * 100), 2) AS porcentaje_descuento,
    COALESCE(t.nombre, 'N/A') AS talla,
    COALESCE(pt.stock, p.stock) AS stock_disponible
FROM productos p
JOIN categorias c ON p.id_categoria = c.id_categoria
JOIN marcas m ON p.id_marca = m.id_marca
LEFT JOIN productos_tallas pt ON p.id_producto = pt.id_producto
LEFT JOIN tallas t ON pt.id_talla = t.id_talla
WHERE p.precio_oferta IS NOT NULL AND p.activo = 1
ORDER BY porcentaje_descuento DESC;