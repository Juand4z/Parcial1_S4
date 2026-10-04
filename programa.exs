defmodule Programa do
  def main do
    confeccionistas= Util.convertir_a_mapa_por(Datos.confeccionistas(), :codigo)
    lineas= Util.convertir_a_mapa_por(Datos.lineas(), :id)
    lotes_completos= solicitar_lote_add(confeccionistas,lineas)
    |> then(fn resultado-> lotes= Datos.lotes() #meto el lote nuevo a la lista de mapas que contiene los lotes
      if resultado == {:error, :formato_invalido} do
        lotes
      else
         [resultado | lotes]
      end
    end)
    validos_e_invalidos Validacion.validar_lotes(lotes_completos, confeccionistas, lineas)
    lotes_validos= validos_e_invalidos.validos #lotes validos son una lista de mapas
    lotes_invalidos= validos_e_invalidos.invalidos

    produccion_por_dia= Reportes.produccion_por_dia

    liquidaciones= Liquidacion.liquidar_todos(confeccionistas, lotes_validos)

    r1= generar_r1(lotes_invalidos) |> Util.mostrar_mensaje()
    r2= generar_r2() |> Util.mostrar_mensaje()
    r3= generar_r3() |> Util.mostrar_mensaje()
    r4= generar_r4() |> Util.mostrar_mensaje()
    r5= generar_r5() |> Util.mostrar_mensaje()
    r6= generar_r6() |> Util.mostrar_mensaje()
    r7= generar_r7() |> Util.mostrar_mensaje()
    r8= generar_r8() |> Util.mostrar_mensaje()


    #faltarian los rankings y la combinacion pero eso lo hacemos cuando lleguemos al punto c
    comprobante= solicitar_comprobante() |> Util.mostrar_mensaje()
  end

  defp solicitar_lote_add(confeccionistas,lineas) do
    resultado = Util.ingresar("Ingrese un lote adicional (confeccionista;linea;dia;prendas;defectos) o Enter para omitir: ", :texto)
    |> verificar_ingreso
    |> Validacion.evaluar_lote_adicional() #esto me retornara algun tipo de tupla con los datos necesarios, ya sea un :agregado, un :rechazado o un :error
    case resultado do #uso el case para imprimir en consola lo que paso con el lote ingresado
       {:agregado, lote} -> Util.mostrar_mensaje("se agrego el lote correctamente")
            lote
       :omitido -> Util.mostrar_mensaje("omitido")

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
