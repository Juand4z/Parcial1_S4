defmodule Programa do
  def main do
    confeccionistas = Util.convertir_a_mapa_por(Datos.confeccionistas(), :codigo) #convierto los datos de una lista de mapas a un solo mapa con clave "el codigo del confeccionista"
    lineas = Util.convertir_a_mapa_por(Datos.lineas(), :id)

    # solicitar_lote_add retorna una lista: [] si no hay lote para agregar, o [lote] si hay uno
    lotes_completos = Datos.lotes() ++ solicitar_lote_add(confeccionistas, lineas) #[dato] ++ [] = [dato], [dato1] ++ [dato2] = [dato1, dato2]

    validos_e_invalidos = Validacion.validar_lotes(lotes_completos, confeccionistas, lineas)
    lotes_validos = validos_e_invalidos.validos #lotes validos son una lista de mapas
    lotes_invalidos = validos_e_invalidos.invalidos

    # mapa %{dia => prendas}, ya no es un texto (sirve luego para el punto C.2)
    produccion_por_dia = Reportes.produccion_por_dia(lotes_validos)

    liquidaciones = Liquidacion.liquidar_todos(confeccionistas, lotes_validos) #para el reporte 3

    Reportes.rechazados_r1(lotes_invalidos) |> Util.mostrar_mensaje() #reporte 1
    Reportes.prendas_por_linea_r2(lotes_validos, lineas) |> Util.mostrar_mensaje() #reporte 2
    Reportes.reporte_r3(produccion_por_dia) |> Util.mostrar_mensaje() #reporte 3

    liquidaciones
    |> Reportes.liquidacion_ordenada() #para el reporte 4
    |> Reportes.reporte_r4()
    |> Util.mostrar_mensaje() #reporte 4

     Reportes.lideres_por_dia(liquidaciones) |> Reportes.reporte_r5() |> Util.mostrar_mensaje()

    lotes_validos
    |> Reportes.mejor_calidad(confeccionistas)
    |> Reportes.reporte_r6()
    |> Util.mostrar_mensaje()

    liquidaciones |> Reportes.totales() |> Reportes.reporte_r7() |> Util.mostrar_mensaje()

    Reportes.en_todas_las_lineas(lotes_validos, lineas, confeccionistas)
    |> Reportes.reporte_r8()
    |> Util.mostrar_mensaje()

    # el comprobante individual se agrega despues
    #faltarian los rankins y la combinacion pero eso lo hacemos cuando lleguemos al punto c

    # r5 a r8 y el comprobante se agregan despues
    #faltarian los rankins y la combinacion pero eso lo hacemos cuando lleguemos al punto c
  end

  defp solicitar_lote_add(confeccionistas, lineas) do
    resultado = Util.ingresar("Ingrese un lote adicional (confeccionista;linea;dia;prendas;defectos) o Enter para omitir: ", :texto)
    |> verificar_ingreso
    |> Validacion.evaluar_lote_adicional(confeccionistas, lineas) #esto me retornara algun tipo de tupla con los datos necesarios, ya sea un :agregado, un :rechazado o un :error

    # cada rama retorna una LISTA para poder concatenarla con ++ a los lotes de Datos
    case resultado do #uso el case para imprimir en consola lo que paso con el lote ingresado
      {:agregado, lote} ->
        Util.mostrar_mensaje("se agrego el lote correctamente")
        [lote]

      :omitido ->
        Util.mostrar_mensaje("omitido")
        []

      {:rechazado, lote, motivo} ->
        Util.mostrar_mensaje("el lote se ingreso correctamente pero fue rechazado por el siguiente motivo: #{motivo}")
        [lote] # se agrega igual para que aparezca en R1, los calculos lo excluyen

      _ ->
        Util.mostrar_mensaje("se ingreso un formato invalido")
        []
    end
  end

  defp verificar_ingreso(mensaje) do #un poquito exagerado este metodo porque el pasersear_lote del modulo Validacion ya verifica que sea binario pero por las dudas tin
    if is_binary(mensaje) do
      mensaje
    else
      ""
    end
  end
end

Programa.main()
