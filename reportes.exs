defmodule Reportes do
  # R1
  def rechazados_r1(lotes_rechazados) do
    # me retornara un mapa con clave "motivo del rechazo" y valor "la cantidad de rechazos por ese motivo"
    frecuencias_motivos = Enum.frequencies_by(lotes_rechazados, fn {_lote, motivo} -> motivo end)

    info1 =
      Enum.map(lotes_rechazados, fn {lote, motivo} ->
        "Lote asociado al confeccionista: #{lote.confeccionista}, fue rechazado por el error: #{motivo}\n"
      end)

    # Enum.map sobre un mapa entrega tuplas {clave, valor}, por eso el patron es {motivo, cantidad}
    info2 =
      Enum.map(frecuencias_motivos, fn {motivo, cantidad} ->
        "El motivo de rechazo: #{motivo}, ocurrio: #{cantidad} veces\n"
      end)

    "\n\n----------R1----------\n#{(Enum.join(info1, "\n")<>"\n"<>Enum.join(info2, "\n"))}"
  end

  @doc """
  R2. Devuelve una lista de mapas `%{id, nombre, puestos, prendas, productividad}`
  ordenada de mayor a menor productividad (prendas / puestos). Las líneas
  sin lotes válidos aparecen con cero prendas.
  """
  def prendas_por_linea_r2(lotes_validos, lineas) do
    # se agrupan en un mapa con clave "codigo de la linea" y valor "el lote que tiene esa linea"
    grupos = Enum.group_by(lotes_validos, fn lote -> lote.linea end)

    resultado =
    lineas
    # retorna una lista de mapas, donde cada mapa es una linea
    |> Map.values()
    # ordena dicha lista de mapas por su id, es decir en orden alfabetico
    |> Enum.sort_by(fn linea -> linea.id end)
    # retorna una lista unicamente con elementos de tipo "prendas de una linea"
    |> Enum.map(fn linea ->
      # luego suma todas las prendas de esa linea
      prendas = grupos |> Map.get(linea.id, []) |> Enum.map(fn x -> x.prendas end) |> Enum.sum()

      # se organiza la informacion en varios mapas para luego abstraerla en un string para retornar el mensaje
      %{
        id: linea.id,
        nombre: linea.nombre,
        puestos: linea.puestos,
        prendas: prendas,
        productividad: productividad(prendas, linea.puestos)
      }
    end)
    # se ordena la lista de mapas de mayor a menor segun la productividad de la linea (una linea es un mapa de la lista de mapas)
    |> Enum.sort_by(fn linea -> linea.productividad end, :desc)
    # retorna una lista de strings donde cada elemento es la informacion de una linea acomodada en mensaje
    |> Enum.map(fn linea ->
      "Linea #{linea.nombre}\n    id: #{linea.id}\n    puestos: #{linea.puestos}\n    prendas totales: #{linea.prendas}\n    productividad: #{linea.productividad} prendas/puesto\n"
    end)
    # fusiono toda la lista en un solo string, separo cada elemento de la anterior lista con un salto de linea "\n"
    |> Enum.join("\n")


    "\n\n----------R2----------\n#{resultado}"
  end

  # guarda que mide la productividad de una linea en prendas por puesto (prendas/puesto)
  defp productividad(prendas, puestos) when is_integer(puestos) and puestos > 0,
    do: prendas / puestos

  # en caso de las prendas no sea un numero entero, hubo un error en el ingreso de los datos, por lo que deberia retornar el error desde la validacion, igualmente la puse por las dudas
  defp productividad(_prendas, _puestos), do: 0.0

  @doc """
  R3 (calculo). Devuelve el mapa `%{dia => prendas}` con los 6 días de producción
  (los días sin lotes válidos valen 0). Es la base de R3 y de
  `combinar_talleres/2`.
  """
  def produccion_por_dia(lotes_validos) do
    # inicializa un mapa con claves "dias del uno al seis"  y valor cero en todas sus claves
    base = Map.new(1..6, fn dia -> {dia, 0} end)

    # itero sobre los lotes validos asignando el valor de las prendas al acumulador, es decir, sumo las prendas de cada dia
    Enum.reduce(lotes_validos, base, fn lote, acc ->
      # va acumulando los valores de las prendas al mapa con clave "dia" y valor "prendas sumandosen"
      Map.update(acc, lote.dia, lote.prendas, fn actual -> actual + lote.prendas end)
    end)
  end

  @doc """
  R3 (texto). Recibe el mapa `%{dia => prendas}` que entrega `produccion_por_dia/1`
  y devuelve el texto del reporte, indicando si se alcanzó la meta cada día.
  """
  def reporte_r3(produccion) do
    # organizo todo en una lista de mapas (ordenada por dia), donde cada mapa contiene la informacion necesaria para el mensaje
    info1 =
      produccion
      |> Enum.sort()
      |> Enum.map(fn {clave, valor} ->
        %{dia: clave, prendas: valor, meta: meta_alcanzada?(valor)}
      end)

    info2 =
      case al_menos_un_dia(info1) do
        :todos -> "    meta todos los dias: lograda\n    meta almenos un dia: lograda"
        :alguno -> "    meta todos los dias: fracasada\n    meta almenos un dia: lograda"
        :ninguno -> "    meta todos los dias: fracasada\n    meta almenos un dia: fracasada"
      end

    # junto todo en un string y separo los elementos por un salto de linea.
    # El pipe se cierra con parentesis porque "<>" tiene mayor precedencia que "|>"
    lineas =
      info1
      |> Enum.map(fn x ->
        "Dia #{x.dia}:\n    prendas: #{x.prendas}\n    meta: #{parsear_meta(x.meta)}\n"
      end)
      |> Enum.join("\n")

    "\n\n----------R3----------\n#{lineas}#{info2}"

  end


  defp parsear_meta(meta) do
    if meta do
      "lograda"
    else
      "fracasada"
    end
  end

  defp meta_alcanzada?(prendas), do: prendas >= 600

  defp al_menos_un_dia(mapa) do
    todos = Enum.all?(mapa, fn %{meta: meta} -> meta == true end) #miro si todos los dias se alcanzo la meta
    ninguno = Enum.any?(mapa, fn %{meta: meta} -> meta == true end)#miro si ningun dia se alcanzo la meta

    case {todos, ninguno} do
      {true, _false} -> :todos #si todos los dias SI se alcanzo la meta y algun dia NO se alcanzo la meta, quiere decir que todos los dias se alcanzo la meta
      {false, true} -> :alguno #si todos los dias NO se alncazo la meta y algun dia SI se alcanzo la meta, quiere decir que algun dia si se alcanzo la meta
      {false, false} -> :ninguno #si todos los dias NO se alcanzo la lmeta y algun dia NO se alcanzo la meta, quiere decir que ningun dia se alcanzo la meta
    end
  end


  @doc """
  R4. Ordena las liquidaciones por pago neto de mayor a menor y las
  numera. Devuelve una lista de tuplas `{liquidacion, posicion}`.
  """
  def liquidacion_ordenada(liquidaciones) do
    liquidaciones
    |> Enum.sort_by(fn liquidacion -> liquidacion.neto end, :desc)
    # numera cada liquidacion empezando en 1, queda una lista de tuplas {liquidacion, posicion}
    |> Enum.with_index(1)
  end

  @doc """
  R4 (texto). Recibe la lista de tuplas `{liquidacion, posicion}` que entrega
  `liquidacion_ordenada/1` y devuelve el texto del reporte.
  """
  def reporte_r4(liquidaciones_ordenadas) do
    lineas =
    liquidaciones_ordenadas
    |> Enum.map(fn {x,posicion} ->
      "#{posicion}. Confeccionista #{x.nombre}\n    codigo: #{x.codigo}\n    prendas: #{x.prendas}\n    pago bruto: #{x.bruto}\n    bonificaciones: #{x.bonificaciones}\n    costo alquiler: #{x.alquiler}\n    pago neto: #{x.neto}\n"
    end)
    |> Enum.join("\n")

    "\n\n----------R4----------\n#{lineas}"
  end
end
