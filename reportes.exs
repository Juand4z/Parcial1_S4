defmodule Reportes do
  @moduledoc """
  Modulo que genera los reportes del taller (R1 a R8).
  Incluye lotes rechazados, prendas por linea, produccion diaria y meta,
  liquidacion ordenada, lider por dia, mejor calidad, total pagado y costo promedio,
  y confeccionistas que trabajaron en todas las lineas.
  - Autores: Luis Miguel Garcia Villanueva, Juan David Arias Sanchez.
  - Fecha: Octubre 5 2026
  - Licencia: GNU GPL v3
  """

@doc """
R1. Funcion que genera el reporte de los lotes rechazados junto a su motivo y la cantidad de rechazados por motivo.

Retorna:
Un String por cada lote rechazado con su respectivo confeccionista y el motivo.
Un String por cada motivo con la cantidad de veces que paso.

Parametros:
'lotes_rechazados' : Lista de tuplas {lote, motivo} con los lotes que no pasaron la validacion.
"""
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
  R2. Funcion que genera el reporte de las prendas elaboradas por cada linea de produccion y su productividad semanal ordenados de mayor a menor.
      Si la linea no tiene lotes validos aparecen 0 prendas.

    Retorna:
    Un string por cada linea de produccion, con nombre, id ,puestos, prendas , productividad (prendas/puestos).

    Parametros:
    'lotes_validos' : Lista de mapas con los lotes que pasaron la validacion.
    'lineas' : Mapa que contiene el id de la linea como clave y el mapa de la linea como valor.
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
  Funcion que calcula las prendas producidas por el taller en cada uno de los 6 dias de produccion.
  Los dias sin lotes validos valen 0.

  Retorna: Un mapa con la estructura %{dia,  prendas}, con las claves del 1 al 6.

  Parametros:
  - 'lotes_validos' : Lista de mapas con los lotes que pasaron la validacion.
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
  R3. Funcion que genera el reporte de las prendas producidas en cada uno de los dias, indicando si se alcanzo
  la meta diaria. Al final indica si la meta se alcanzo todos los dias, al menos un dia o ningun dia.

  Retorna:
  Un String con el titulo del reporte, un bloque por cada dia con sus prendas y si se alcanzo la meta,
  y al final el estado de la meta (todos los dias o al menos un dia).

  Parametros:
  - 'produccion' : Mapa %{dia, prendas} que retorna produccion_por_dia.
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
  Funcion que ordena las liquidaciones por pago neto de mayor a menor y las numera. Es la base del reporte R4.

  Retorna: Una lista de tuplas {liquidacion, posicion}, donde la posicion empieza en 1.

  Parametros:
  - 'liquidaciones' : Lista de mapas que retorna Liquidacion.liquidar_todos, uno por confeccionista.
  """
  def liquidacion_ordenada(liquidaciones) do
    liquidaciones
    |> Enum.sort_by(fn liquidacion -> liquidacion.neto end, :desc)
    # numera cada liquidacion empezando en 1, queda una lista de tuplas {liquidacion, posicion}
    |> Enum.with_index(1)
  end

  @doc """
  R4. Funcion que genera el reporte de la liquidacion de todos los confeccionistas, numerada y ordenada
  por pago neto de mayor a menor.

  Retorna:
  Un String con el titulo del reporte y un confeccionista con su posicion, nombre, codigo,
  prendas, pago bruto, bonificaciones, costo del alquiler y pago neto.

  Parametros:
  - 'liquidaciones_ordenadas' : Lista de tuplas {liquidacion, posicion} que retorna liquidacion_ordenada.
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

  @doc """
  R5. Funcion que genera el reporte del confeccionista que produjo mas prendas cada dia.

  Retorna: Un string con el titulo, una linea por dia (si hay empate se muestran todos
  los empatados, y si no hubo lotes validos se indica) y al final quien ocupo el primer
  lugar mas dias y cuantos (con empates incluidos).

  Parametros:
  - 'lotes_validos' : Lista de mapas con los lotes que pasaron la validacion.
  - 'confeccionistas' : Mapa con clave "codigo" y valor el mapa del confeccionista.
  """
  def lideres_por_dia_r5(lotes_validos, confeccionistas) do
    # lista de tuplas {dia, [codigos lideres], prendas} para los 6 dias
    lideres = lideres_por_dia(lotes_validos)

    # convierto cada tupla en una linea de texto
    info1 =
      lideres
      |> Enum.map(fn lider -> linea_lider_dia(lider, confeccionistas) end)
      |> Enum.join("\n")

    # mensaje final con el confeccionista que mas dias fue primero
    info2 = resumen_lider_semana(lideres, confeccionistas)

    "=== R5. Confeccionista lider por dia ===\n" <> info1 <> "\n" <> info2
  end

  defp lideres_por_dia(lotes_validos) do
    # mapa con clave "dia" y valor "lista de lotes de ese dia"
    por_dia = Enum.group_by(lotes_validos, fn lote -> lote.dia end)

    # recorro los 6 dias, Map.get/3 evita nil en los dias sin lotes
    Enum.map(1..6, fn dia -> lider_del_dia(dia, Map.get(por_dia, dia, [])) end)
  end

  defp lider_del_dia(dia, lotes_dia) do
    # lista de tuplas {codigo, prendas del dia}, sumando todas las lineas del confeccionista
    totales =
      lotes_dia
      |> Enum.group_by(fn lote -> lote.confeccionista end, fn lote -> lote.prendas end)
      |> Enum.map(fn {codigo, prendas} -> {codigo, Enum.sum(prendas)} end)

    case totales do
      # dia sin lotes validos
      [] ->
        {dia, [], 0}

      _ ->
        # mayor cantidad de prendas del dia
        maximo = totales |> Enum.map(fn {_codigo, prendas} -> prendas end) |> Enum.max()

        # todos los que igualan el maximo (empates), ordenados por codigo
        codigos =
          totales
          |> Enum.filter(fn {_codigo, prendas} -> prendas == maximo end)
          |> Enum.map(fn {codigo, _prendas} -> codigo end)
          |> Enum.sort()

        {dia, codigos, maximo}
    end
  end

  defp linea_lider_dia({dia, [], _prendas}, _confeccionistas),
    do: "El dia #{dia} no tuvo lotes validos"

  defp linea_lider_dia({dia, codigos, prendas}, confeccionistas),
    do: "El dia #{dia} lidero #{nombres(codigos, confeccionistas)} con #{prendas} prendas"

  defp resumen_lider_semana(lideres, confeccionistas) do
    # junto los codigos de todos los dias (con empates) y cuento cuantas veces aparece cada uno
    victorias =
      lideres
      |> Enum.flat_map(fn {_dia, codigos, _prendas} -> codigos end)
      |> Enum.frequencies()

    case Map.values(victorias) do
      # ningun dia tuvo lotes validos
      [] ->
        "Ningun dia tuvo lotes validos, no hay primer lugar semanal"

      conteos ->
        mayor = Enum.max(conteos)

        # si hay empate en cantidad de dias se incluyen todos
        codigos =
          victorias
          |> Enum.filter(fn {_codigo, dias} -> dias == mayor end)
          |> Enum.map(fn {codigo, _dias} -> codigo end)
          |> Enum.sort()

        "Ocupo el primer lugar mas dias: #{nombres(codigos, confeccionistas)} con #{mayor} dia(s)"
    end
  end


  defp nombres(codigos, confeccionistas) do
    codigos
    |> Enum.map(fn codigo -> "#{Map.get(confeccionistas, codigo).nombre} (#{codigo})" end)
    |> Enum.join(", ")
  end

  @doc """
  R6. Funcion que genera el reporte del confeccionista con el menor porcentaje de defectos ponderado por prendas entre quienes tengan al menos 3 lotes validos.

  Retorna: Un string con el titulo y el ganador (todos los empatados si los hay),
  o un aviso si nadie cumple el minimo de 3 lotes validos.

  Parametros:
  - 'lotes_validos' : Lista de mapas con los lotes validados.
  - 'confeccionistas' : Mapa con clave "codigo" y valor el mapa del confeccionista.
  """
  def mejor_calidad_r6(lotes_validos, confeccionistas) do
    # lista de tuplas {codigo, porcentaje ponderado} solo de quienes tienen 3 o mas lotes validos
    candidatos =
      lotes_validos
      |> Enum.group_by(fn lote -> lote.confeccionista end)
      |> Enum.filter(fn {_codigo, lotes} -> length(lotes) >= 3 end)
      |> Enum.map(fn {codigo, lotes} -> {codigo, porcentaje_ponderado(lotes)} end)

    titulo = "=== R6. Confeccionista con mejor calidad ===\n"

    case candidatos do
      # nadie llego al minimo de lotes
      [] ->
        titulo <> "Ningun confeccionista tiene al menos 3 lotes validos"

      _ ->
        # el menor porcentaje es el de mejor calidad
        menor = candidatos |> Enum.map(fn {_codigo, porcentaje} -> porcentaje end) |> Enum.min()

        mensajes =
          candidatos
          |> Enum.filter(fn {_codigo, porcentaje} -> porcentaje == menor end)
          |> Enum.sort_by(fn {codigo, _porcentaje} -> codigo end)
          |> Enum.map(fn {codigo, porcentaje} ->
            "#{nombres([codigo], confeccionistas)} con #{Util.formater(porcentaje)}% de defectos ponderado"
          end)
          |> Enum.join("\n")

        titulo <> mensajes
    end
  end


  defp porcentaje_ponderado(lotes) do
    suma_ponderada = lotes |> Enum.map(fn lote -> lote.defectos * lote.prendas end) |> Enum.sum()
    total_prendas = lotes |> Enum.map(fn lote -> lote.prendas end) |> Enum.sum()

    suma_ponderada / total_prendas
  end

  @doc """
  R7. Funcion que genera el reporte del total pagado por el taller en la semana
  y el costo promedio pagado por prenda valida (total pagado / total de prendas validas).

  Retorna: Un string con el titulo, el total pagado y el promedio. Si no hay prendas
  validas indica que el promedio no puede calcularse.

  Parametros:
  - 'liquidaciones' : Lista de mapas que retorna Liquidacion.liquidar_todos.
  """
  def costo_promedio_r7(liquidaciones) do
    # el taller paga el neto de cada confeccionista
    total_pagado = liquidaciones |> Enum.map(fn liq -> liq.neto end) |> Enum.sum()
    total_prendas = liquidaciones |> Enum.map(fn liq -> liq.prendas end) |> Enum.sum()

    # si no hay prendas validas la division seria por cero, por eso se usa if
    promedio =
      if total_prendas == 0 do
        "El promedio por prenda no puede calcularse porque no hay prendas validas"
      else
        "Costo promedio por prenda valida: $#{Util.formater(total_pagado / total_prendas)}"
      end

    "=== R7. Total pagado y costo promedio por prenda ===\n" <>
      "Total pagado por el taller: $#{Util.formater(total_pagado)}\n" <> promedio
  end

  @doc """
  R8. Funcion que genera el reporte de los confeccionistas que elaboraron al menos
  un lote valido en todas las lineas de produccion.

  Retorna: Un string con el titulo y la lista de confeccionistas o un aviso si no hay ninguno.

  Parametros:
  - 'lotes_validos' : Lista de mapas con los lotes validados.
  - 'lineas' : Mapa con clave "id" y valor el mapa de la linea.
  - 'confeccionistas' : Mapa con clave "codigo" y valor el mapa del confeccionista.
  """
  def en_todas_las_lineas_r8(lotes_validos, lineas, confeccionistas) do
    # lista con los ids de todas las lineas registradas
    ids_lineas = Map.keys(lineas)

    codigos =
      lotes_validos
      # mapa con clave "codigo" y valor "lista de lineas donde trabajo" (group_by/3 transforma el valor)
      |> Enum.group_by(fn lote -> lote.confeccionista end, fn lote -> lote.linea end)
      # me quedo con quienes tienen TODAS las lineas dentro de las que trabajaron
      |> Enum.filter(fn {_codigo, lineas_trabajadas} ->
        Enum.all?(ids_lineas, fn id -> Enum.member?(lineas_trabajadas, id) end)
      end)
      |> Enum.map(fn {codigo, _lineas_trabajadas} -> codigo end)
      |> Enum.sort()

    titulo = "=== R8. Confeccionistas que trabajaron en todas las lineas ===\n"

    case codigos do
      [] -> titulo <> "Ningun confeccionista trabajo en todas las lineas"
      _ -> titulo <> nombres(codigos, confeccionistas)
    end
  end
end
