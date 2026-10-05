defmodule Reportes do
  # R1
  def rechazados_r1(lotes_rechazados) do
    # me retornara un mapa con clave "motivo del rechazo" y valor "la cantidad de rechazos por ese motivo"
    frecuencias_motivos = Enum.frequencies_by(lotes_rechazados, fn {_lote, motivo} -> motivo end)

    # retorno la lista de mapas, de los lotes rechazados junto con un mapa que agrupa cada motivo de rechazo como clave y el valor de su frecuencia como valor
    {lotes_rechazados, frecuencias_motivos}

    info1 =
      Enum.map(lotes_rechazados, fn {lote, motivo} ->
        "El lote del confeccionista #{lote.confeccionista} fue rechazado por #{motivo}"
      end)

    info2 =
      Enum.map(frecuencias_motivos, fn %{calve, valor} ->
        "El motivo de rechazo #{clave}, ocurrio #{valor} veces"
      end)

    resultado = Enum.join(info1, "\n") <> "\n" <> Enum.join(info2, "\n")
  end

  @doc """
  R2. Devuelve una lista de mapas `%{id, nombre, puestos, prendas, productividad}`
  ordenada de mayor a menor productividad (prendas / puestos). Las líneas
  sin lotes válidos aparecen con cero prendas.
  """
  def prendas_por_linea_r2(lotes_validos, lineas) do
    # se agrupan en un mapa con clave "codigo de la linea" y valor "el lote que tiene esa linea"
    grupos = Enum.group_by(lotes_validos, fn lote -> lote.linea end)

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
      "La linea #{linea.nombre} con id #{linea.id} tiene #{linea.puestos} puestos y tiene #{linea.prendas} en total, con una productividad de #{linea.productividad} prendas por puesto"
    end)
    # fusiono toda la lista en un solo string, separo cada elemento de la anterior lista con un salto de linea "\n"
    |> Enum.join("\n")
  end

  # guarda que mide la productividad de una linea en prendas por puesto (prendas/puesto)
  defp productividad(prendas, puestos) when is_integer(puestos) and puestos > 0,
    do: prendas / puestos

  # en caso de las prendas no sea un numero entero, hubo un error en el ingreso de los datos, por lo que deberia retornar el error desde la validacion, igualmente la puse por las dudas
  defp productividad(_prendas, _puestos), do: 0.0

  @doc """
  R3 Devuelve el mapa `%{dia => prendas}` con los 6 días de producción
  (los días sin lotes válidos valen 0). Es la base de R3 y de
  `combinar_talleres/2`.
  """
  def produccion_por_dia(lotes_validos) do
    # inicializa un mapa con claves "dias del uno al seis"  y valor cero en todas sus claves
    base = Map.new(1..6, fn dia -> {dia, 0} end)

    # itero sobre los lotes validos asignando el valor de las prendas al acumulador, es decir, sumo las prendas de cada dia
    info1 =
      Enum.reduce(lotes_validos, base, fn lote, acc ->
        # va acumulando los valores de las prendas al mapa con clave "dia" y valor "prendas sumandosen"
        Map.update(acc, lote.dia, lote.prendas, fn actual -> actual + lote.prendas end)
      end)
      # organizo todo en una lista de mapas, donde cada mapa contiene la informacion necesaria para realizar el mensaje finalmente
      |> Enum.map(fn {calve, valor} ->
        %{dia: clave, prendas: valor, meta: meta_alcanzada?(valor)}
      end)

    # junto todo en un string y separo los elementos por un salto de linea

    info2 =
      case al_menos_un_dia(info1) do
        :todos -> "\nSe alcanzo la meta todos los dias"
        :alguno -> "\nSe alcanzo la meta al menos un dia"
        :ninguno -> "\nNo se alcanzo la meta ningun dia"
      end

    info1
    |> Enum.map(fn x ->
      if x.meta do
        # si la meta es true, si se alcanzo y asigna un elemento a lista que se esta generando con este mensaje
        "el dia #{x.dia} se obtuvieron #{x.prendas} y si se alcanzo la meta"
      else
        # caso contraio pasa esto
        "el dia #{x.dia} se obtuvieron #{x.prendas} y no se alcanzo la meta"
      end
    end)
    |> Enum.join("\n") <> info2
  end

  @doc """
  Indica si la producción de un día alcanza la meta diaria del taller.
  """
  def meta_alcanzada?(prendas), do: prendas >= 600

  def al_menos_un_dia(mapa) do
    todos = Enum.all?(mapa, fn %{meta: meta} -> meta == true end) #miro si todos los dias se alcanzo la meta
    ninguno = Enum.any?(mapa, fn %{meta: meta} -> meta == true end)#miro si ningun dia se alcanzo la meta

    case {todos, ninguno} do
      {true, _false} -> :todos #si todos los dias SI se alcanzo la meta y algun dia NO se alcanzo la meta, quiere decir que todos los dias se alcanzo la meta
      {false, true} -> :alguno #si todos los dias NO se alncazo la meta y algun dia SI se alcanzo la meta, quiere decir que algun dia si se alcanzo la meta
      {false, false} -> :ninguno #si todos los dias NO se alcanzo la lmeta y algun dia NO se alcanzo la meta, quiere decir que ningun dia se alcanzo la meta
    end
  end

  # ------------------------------------------------------------------
  # R4. Liquidación ordenada
  # ------------------------------------------------------------------

  @doc """
  R4. Ordena las liquidaciones por pago neto de mayor a menor y las
  numera. Devuelve una lista de tuplas `{liquidacion, posicion}`.
  """
  def liquidacion_ordenada(liquidaciones) do
    liquidaciones
    |> Enum.sort_by(fn liquidacion -> liquidacion.neto end, :desc)
    |> Enun.map(fn x-> "Confeccionista #{x.nombre} con codigo #{x.codigo}, prendas #{x.prendas}, pago bruto #{x.bruto}, bonificaciones #{x.bonificaciones}, costo alquiler #{x.alquiler}, pago neto #{x.neto}"end)
    |> Enum.join("\n")
  end

  def confeccionista_mas_prendas(liquidaciones) do
    liquidaciones
    |> Enum.sort_by()
  end

end
