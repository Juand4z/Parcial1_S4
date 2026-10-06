defmodule Programa do
  @moduledoc """
  Modulo principal del programa.
  Coordina el flujo completo: carga los datos, solicita un lote adicional por consola,
  valida los lotes, calcula las liquidaciones y muestra los reportes R1 a R8.
  - Autores: Luis Miguel Garcia Villanueva, Juan David Arias Sanchez.
  - Fecha: Octubre 5 2026
  - Licencia: GNU GPL v3
  """

  @doc """
    Funcion principal del programa. Coordina el flujo completo del taller, de principio a fin:
    1. Carga los confeccionistas y las lineas de Datos y los indexa en mapas (por 'codigo' y por 'id') con Util.convertir_a_mapa_por/2.
    2. Solicita por consola un lote adicional (confeccionista;linea;dia;prendas;defectos) y lo concatena a los lotes de Datos.
    3. Valida todos los lotes y los separa en validos e invalidos con Validacion.validar_lotes/3.
    4. Calcula la produccion por dia y las liquidaciones de todos los confeccionistas.
    5. Muestra por consola los reportes R1 a R8.
    6. Punto C.1: muestra cuatro rankings de liquidaciones usando keyword lists con distintas opciones (campo, orden y limite).
    7. Punto C.2: combina la produccion por dia del taller con la de un taller aliado y muestra el reporte.
    8. Solicita el codigo de un confeccionista y muestra su comprobante individual (una sola consulta por ejecucion).
  """
  def main do
    datos_confeccionistas = Util.filtrar_confeccionistas(Datos.confeccionistas())
    datos_lineas = Util.filtrar_lineas(Datos.lineas())
    datos_lotes = Util.filtrar_lotes(Datos.lotes())

    avisar_descartados("confeccionistas", datos_confeccionistas.descartados)
    avisar_descartados("lineas", datos_lineas.descartados)
    avisar_descartados("lotes", datos_lotes.descartados)

    #con los datos ya filtrados, procedemos a ingresar los confeccionistas y las lineas como un mapa, que proviene de una lista previamente indexada por la funcion convertir a mapa por
    confeccionistas = Util.convertir_a_mapa_por(datos_confeccionistas.validos, :codigo)
    lineas = Util.convertir_a_mapa_por(datos_lineas.validos, :id)

    # solicitar_lote_add retorna una lista: [] si no hay lote para agregar, o [lote] si hay uno
    # [dato] ++ [] = [dato], [dato1] ++ [dato2] = [dato1, dato2]
    lotes_completos = datos_lotes.validos ++ solicitar_lote_add(confeccionistas, lineas)

    validos_e_invalidos = Validacion.validar_lotes(lotes_completos, confeccionistas, lineas)
    # lotes validos son una lista de mapas
    lotes_validos = validos_e_invalidos.validos
    lotes_invalidos = validos_e_invalidos.invalidos

    # mapa %{dia => prendas}, ya no es un texto (sirve luego para el punto C.2)
    produccion_por_dia = Reportes.produccion_por_dia(lotes_validos)

    # para el reporte 3
    liquidaciones = Liquidacion.liquidar_todos(confeccionistas, lotes_validos)

    # reporte 1
    Reportes.rechazados_r1(lotes_invalidos) |> Util.mostrar_mensaje()
    # reporte 2
    Reportes.prendas_por_linea_r2(lotes_validos, lineas) |> Util.mostrar_mensaje()
    # reporte 3
    Reportes.reporte_r3(produccion_por_dia) |> Util.mostrar_mensaje()

    liquidaciones
    # para el reporte 4
    |> Reportes.liquidacion_ordenada()
    # el string bonito
    |> Reportes.reporte_r4()
    # reporte 4
    |> Util.mostrar_mensaje()

    # le ingresamos las liquidaciones a liderespordia y esos lideres se los pasamos al reporte 5 para el string bonito
    Reportes.lideres_por_dia(liquidaciones) |> Reportes.reporte_r5() |> Util.mostrar_mensaje()

    lotes_validos
    # le pasamos el mapa, previamente indexado a mapa a la funcion mejor_calidad, para luego generar elstring con reporte_r6
    |> Reportes.mejor_calidad(confeccionistas)
    |> Reportes.reporte_r6()
    |> Util.mostrar_mensaje()

    # le damos las liquidaciones a totales para que me genere los gatos del taller con reporte_r7
    liquidaciones |> Reportes.totales() |> Reportes.reporte_r7() |> Util.mostrar_mensaje()

    # le ingresamos los datos necesarios a la funcion en todas las lineas para que me retorne los confeccionistas que tuvieron al menos un lote valido en todas las lineas
    Reportes.en_todas_las_lineas(lotes_validos, lineas, confeccionistas)
    |> Reportes.reporte_r8()
    |> Util.mostrar_mensaje()

    # c.1
    consultas = [
      [],
      [campo: :prendas, limite: 3],
      [orden: :asc, campo: :bruto],
      # clave repetida keyword.get usa la primera osea :prendas
      [campo: :prendas, campo: :neto]
    ]

    Enum.each(consultas, fn opciones ->
      liquidaciones
      |> Reportes.ranking(opciones)
      |> Reportes.reporte_ranking_c1(opciones)
      |> Util.mostrar_mensaje()
    end)

    # c.2
    taller_aliado = %{1 => 550, 2 => 620, 3 => 480, 5 => 710, 7 => 200}
    Reportes.reporte_c2(produccion_por_dia, taller_aliado) |> Util.mostrar_mensaje()

    # comprobante
    solicitar_comprobante(liquidaciones)
  end

  defp solicitar_lote_add(confeccionistas, lineas) do
    resultado =
      Util.ingresar(
        "Ingrese un lote adicional (confeccionista;linea;dia;prendas;defectos) o Enter para omitir: ",
        :texto
      )
      |> verificar_ingreso
      # esto me retornara algun tipo de tupla con los datos necesarios, ya sea un :agregado, un :rechazado o un :error
      |> Validacion.evaluar_lote_adicional(confeccionistas, lineas)

    # cada rama retorna una LISTA para poder concatenarla con ++ a los lotes de Datos
    # uso el case para imprimir en consola lo que paso con el lote ingresado
    case resultado do
      {:agregado, lote} ->
        Util.mostrar_mensaje("se agrego el lote correctamente")
        [lote]

      :omitido ->
        Util.mostrar_mensaje("omitido")
        []

      {:rechazado, lote, motivo} ->
        Util.mostrar_mensaje(
          "el lote se ingreso correctamente pero fue rechazado por el siguiente motivo: #{motivo}"
        )

        # se agrega igual para que aparezca en R1, los calculos lo excluyen
        [lote]

      _ ->
        Util.mostrar_mensaje("se ingreso un formato invalido")
        []
    end
  end

  # un poquito exagerado este metodo porque el pasersear_lote del modulo Validacion ya verifica que sea binario pero por las dudas tin
  defp verificar_ingreso(mensaje) do
    if is_binary(mensaje) do
      mensaje
    else
      ""
    end
  end

  defp solicitar_comprobante(liquidaciones) do
    codigo =
      Util.ingresar("\nIngrese el codigo de un confeccionista para ver su comprobante: ", :texto)

    case Reportes.buscar_liquidacion(liquidaciones, codigo) do
      {:ok, liquidacion} ->
        liquidacion |> Reportes.comprobante() |> Util.mostrar_mensaje()

      :error ->
        Util.mostrar_mensaje("El codigo #{codigo} no existe, no hay comprobante para mostrar")
    end
  end




  #funciones para validar datos erroneos, esto es para que no afecte las validaciones ni los resultados de las reglas de negocio
  #esta validacion se construyo usando la logica de la inteligencia artifial, la cual sugirio que filtraramos los datos antes de ingresarlos al programa
  #esto con el proposito de separar los errores de datos mal ingresados con los errores de las reglas de negocio
  defp avisar_descartados(_nombre, []), do: :ok

  defp avisar_descartados(nombre, descartados) do
    Util.mostrar_mensaje("Aviso: se descartaron #{length(descartados)} elemento(s) de #{nombre} por datos mal formados:")

    Enum.each(descartados, fn {elemento, motivo} ->
      Util.mostrar_mensaje("  - #{motivo}: #{inspect(elemento)}")
    end)
  end
end

Programa.main()
