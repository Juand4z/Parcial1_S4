defmodule Programa do
  def main do
    confeccionistas = Util.convertir_a_mapa_por(Datos.confeccionistas(), :codigo)
    lineas = Util.convertir_a_mapa_por(Datos.lineas(), :id)

    # solicitar_lote_add retorna una lista: [] si no hay lote para agregar, o [lote] si hay uno
    lotes_completos = Datos.lotes() ++ solicitar_lote_add(confeccionistas, lineas)

    validos_e_invalidos = Validacion.validar_lotes(lotes_completos, confeccionistas, lineas)
    lotes_validos = validos_e_invalidos.validos #lotes validos son una lista de mapas
    lotes_invalidos = validos_e_invalidos.invalidos

    # mapa %{dia => prendas}, ya no es un texto (sirve luego para el punto C.2)
    produccion_por_dia = Reportes.produccion_por_dia(lotes_validos)

    liquidaciones = Liquidacion.liquidar_todos(confeccionistas, lotes_validos)

    #faltarian los rankings y la combinacion pero eso lo hacemos cuando lleguemos al punto c
    comprobante= solicitar_comprobante() |> Util.mostrar_mensaje()
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

       {:rechazado, lote, motivo} -> Util.mostrar_mensaje("el lote se ingreso correctamente pero fue rechazado por el siguiente motivo: #{motivo}")
            lote
       _ -> Util.mostrar_mensaje("se ingreso un formato invalido")

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
