-- Permite que dirección / maestra validen el código QR en la puerta.
-- El RPC ya existe (FIX_SISTEMA_QR_TEMPORAL.sql). Esto solo da permiso de ejecución.

GRANT EXECUTE ON FUNCTION public.generar_codigo_qr() TO authenticated;
GRANT EXECUTE ON FUNCTION public.validar_qr_temporal(TEXT, UUID) TO authenticated;
