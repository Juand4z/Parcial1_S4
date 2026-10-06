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
      "Linea #{linea.nombre}\n    id: #{linea.id}\n    puestos: #{linea.puestos}\n    prendas totales: #{linea.prendas}\n    productividad: #{Util.formater(linea.productividad)} prendas/puesto\n"
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

    "\n\n----------R3----------\n#{lineas}\n\n#{info2}"

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
  Funcion que calcula el confeccionista (o confeccionistas, si hay empate) que mas prendas
  produjo en cada uno de los 6 dias de produccion.

  Retorna:
  Una lista de 6 mapas (uno por dia) con la estructura %{dia, prendas, lideres}.
  'lideres' es una lista con TODOS los confeccionistas que igualan el maximo de prendas ese dia,
  cada uno como un mapa %{codigo, nombre, dia, prendas}.
  Si 'lideres' es una lista vacia significa que ese dia no hubo lotes validos (y 'prendas' vale 0).

  Parametros:
  - 'liquidaciones' : Lista de mapas que retorna Liquidacion.liquidar_todos, uno por confeccionista.
  """
  def lideres_por_dia(liquidaciones) do #entra una lista de mapas donde cada elemento es una liquidacion
    # lista de mapas, un mapa por cada dia que trabajo cada confeccionista: %{codigo, nombre, dia, prendas}
    entradas =
      liquidaciones
      |> Enum.flat_map(fn liquidacion -> #flatmap me permite reestructurar la lista de mapas que es liquidaciones en una lista plana como de un nivel nomas, en vez de una lista de listas
        Enum.map(liquidacion.detalle, fn detalle_dia -> #lo que hace este map es agarrar el mapa de detalle y retornar una lista de mapas con la informacion requerida para luego agrupar cada confeccionista con su dia y su produccion
          %{
            codigo: liquidacion.codigo,
            nombre: liquidacion.nombre,
            dia: detalle_dia.dia,
            prendas: detalle_dia.prendas
          }
        end)
      end)

    # mapa con clave "dia" y valor "lista de lo que produjo cada confeccionista ese dia"
    grupos = Enum.group_by(entradas, fn entrada -> entrada.dia end) #agrupo la lista de mapas que me retorno el flatmap en un mapa

    1..6 #simplemente una lista con elementos del 1 al 6 que me van a servir para ver quien fue el que mas produjo en un dia especifico
    |> Enum.map(fn dia -> #map que me retorna una lista de mapas
      # Map.get/3 con [] para que un dia sin lotes no de nil
      candidatos = Map.get(grupos, dia, []) #map get me retorna un mapa de los que mas trabajaron en un dia concreto, si nadie trabajo en algun dia no me retorna "nil" para es edia sino que me retorna "[]'

      case candidatos do
        # si nadie trabajo ese dia, no hay lider
        [] ->
          %{dia: dia, prendas: 0, lideres: []}

        _ ->
          maximo = candidatos |> Enum.map(fn c -> c.prendas end) |> Enum.max() # miro cual es la maxima produccion de prendas un dia concreto
          # me quedo con todos los que igualan el maximo, asi se manejan los empates
          lideres = Enum.filter(candidatos, fn c -> c.prendas == maximo end) #aqui busco los que obtuvieron dicha produccion maxima el mismo dia concreto
          %{dia: dia, prendas: maximo, lideres: lideres}
      end
    end)
  end

  @doc """
  R5. Funcion que genera el reporte del lider de cada dia y de quien ocupo el primer lugar en mas dias.

  Retorna:
  Un String con el titulo del reporte, un bloque por cada dia con su lider (o lideres, si hay empate) y las prendas
  que produjo (o 'sin lotes validos' si ese dia nadie trabajo) y, al final, quien ocupo el primer lugar en mas dias.

  Parametros:
  - 'lideres_dias' : Lista de mapas %{dia, prendas, lideres} que retorna lideres_por_dia/1.
  """
  def reporte_r5(lideres_dias) do
    lineas =
      lideres_dias
      |> Enum.map(fn dia ->
        case dia.lideres do
          [] -> "Dia #{dia.dia}:\n    sin lotes validos\n"
          lideres -> "Dia #{dia.dia}:\n    lider: #{nombres_con_codigo(lideres)}\n    prendas: #{dia.prendas}\n"
        end
      end)
      |> Enum.join("\n")

    "\n\n----------R5----------\n#{lineas}\n#{primer_lugar_mas_dias(lideres_dias)}"
  end

  # recibe una lista de mapas con :nombre y :codigo y los junta en un solo texto separado por comas
  defp nombres_con_codigo(personas) do
    personas
    |> Enum.map(fn persona -> "#{persona.nombre} (#{persona.codigo})" end)
    |> Enum.join(", ")
  end

  # indica quien ocupo el primer lugar mas dias y cuantos, si hay empate incluye a todos los empatados
  # (en un dia con empate, cada empatado suma un primer lugar)
  defp primer_lugar_mas_dias(lideres_dias) do
    # una sola lista con todos los lideres de todos los dias
    todos_los_lideres = Enum.flat_map(lideres_dias, fn dia -> dia.lideres end)
    # mapa con clave "codigo" y valor "cuantos dias fue lider"
    conteo = Enum.frequencies_by(todos_los_lideres, fn lider -> lider.codigo end)
    # mapa para recuperar el nombre a partir del codigo
    nombres = Map.new(todos_los_lideres, fn lider -> {lider.codigo, lider.nombre} end)

    case Map.values(conteo) do
      # si no hay ningun lider es porque ningun dia tuvo lotes validos
      [] ->
        "Ningun dia tuvo lotes validos, no hay primer lugar semanal"

      veces_por_persona ->
        maximo = Enum.max(veces_por_persona)

        ganadores =
          conteo
          |> Enum.filter(fn {_codigo, veces} -> veces == maximo end)
          |> Enum.sort()
          |> Enum.map(fn {codigo, _veces} -> %{codigo: codigo, nombre: Map.get(nombres, codigo)} end)
          |> nombres_con_codigo()

        "Primer lugar en mas dias (#{maximo} dia(s)): #{ganadores}"
    end
  end


  @doc """
  R6 (calculo). Funcion que determina el confeccionista con mejor calidad, es decir, el menor porcentaje
  de defectos ponderado por prendas. Solo participan los confeccionistas con al menos 3 lotes validos.
  El porcentaje ponderado es suma(defectos * prendas) / suma(prendas).

  Retorna:
  - {:ok, mejores, elegibles} : 'elegibles' es la lista de mapas %{codigo, nombre, lotes, ponderado, simple}
    ordenada del mejor al peor porcentaje ponderado; 'mejores' son todos los que igualan el menor
    porcentaje ponderado (por si hay empate).
  - {:error, :sin_elegibles} : Ningun confeccionista tiene al menos 3 lotes validos.

  Parametros:
  - 'lotes_validos' : Lista de mapas con los lotes que pasaron la validacion.
  - 'confeccionistas' : Mapa que contiene el codigo del confeccionista como clave y el mapa del confeccionista como valor.
  """
  def mejor_calidad(lotes_validos, confeccionistas) do
    elegibles =
      lotes_validos
      # mapa con clave "codigo del confeccionista" y valor "lista de sus lotes validos"
      |> Enum.group_by(fn lote -> lote.confeccionista end)
      # solo participan los que tienen al menos 3 lotes validos
      |> Enum.filter(fn {_codigo, lotes} -> length(lotes) >= 3 end)
      |> Enum.map(fn {codigo, lotes} ->
        %{
          codigo: codigo,
          nombre: Map.get(confeccionistas, codigo).nombre,
          lotes: length(lotes),
          ponderado: porcentaje_ponderado(lotes),
          simple: porcentaje_simple(lotes)
        }
      end)
      |> Enum.sort_by(fn e -> {e.ponderado, e.codigo} end)

    # el case evita usar Enum.min_by sobre una lista vacia, que lanzaria un error
    case elegibles do
      [] ->
        {:error, :sin_elegibles}

      [primero | _resto] ->
        mejores = Enum.filter(elegibles, fn e -> e.ponderado == primero.ponderado end)
        {:ok, mejores, elegibles}
    end
  end

  @doc """
  R6. Funcion que genera el reporte de mejor calidad. Tiene dos cabezas de funcion segun lo que retorne mejor_calidad/2.

  Retorna:
  Un String con el titulo del reporte y:
  - Si hubo elegibles: el o los confeccionistas con mejor calidad y una comparacion de todos los elegibles
    mostrando lotes, defectos ponderado y defectos promedio simple (para ver la diferencia entre ambas medidas).
  - Si no hubo elegibles: un mensaje indicando que ningun confeccionista tiene al menos 3 lotes validos.

  Parametros:
  - 'resultado' : La tupla {:ok, mejores, elegibles} o {:error, :sin_elegibles} que retorna mejor_calidad/2.
  """
  def reporte_r6({:error, :sin_elegibles}) do
    "\n\n----------R6----------\nNingun confeccionista tiene al menos 3 lotes validos"
  end

  def reporte_r6({:ok, mejores, elegibles}) do
    ganadores =
      mejores
      |> Enum.map(fn m ->
        "#{m.nombre} (#{m.codigo}) con #{Util.formater(m.ponderado)} % de defectos ponderado"
      end)
      |> Enum.join("\n")

    # muestra a todos los elegibles con ambas medidas para poder ver la diferencia entre ponderado y promedio simple
    comparacion =
      elegibles
      |> Enum.map(fn e ->
        "#{e.nombre} (#{e.codigo})\n    lotes: #{e.lotes}\n    defectos ponderado: #{Util.formater(e.ponderado)} %\n    defectos promedio simple: #{Util.formater(e.simple)} %\n"
      end)
      |> Enum.join("\n")

    "\n\n----------R6----------\nMejor calidad:\n#{ganadores}\n\nComparacion entre ponderado y promedio simple:\n#{comparacion}"
  end

  # porcentaje_ponderado = suma(defectos * prendas) / suma(prendas)
  defp porcentaje_ponderado(lotes) do
    defectos_por_prendas =
      lotes |> Enum.map(fn lote -> lote.defectos * lote.prendas end) |> Enum.sum()

    prendas = lotes |> Enum.map(fn lote -> lote.prendas end) |> Enum.sum()

    defectos_por_prendas / prendas
  end

  # promedio simple de los porcentajes de defectos de cada lote
  defp porcentaje_simple(lotes) do
    suma_defectos = lotes |> Enum.map(fn lote -> lote.defectos end) |> Enum.sum()
    suma_defectos / length(lotes)
  end



  @doc """
  R7. Funcion que calcula el total que debe pagar el taller, el total de prendas validas
  y el costo promedio por prenda valida.

  Retorna:
  Un mapa con la estructura %{total_pagado, total_prendas, promedio}.
  El promedio es :no_calculable cuando no hay prendas validas (evita dividir por cero).

  Parametros:
  - 'liquidaciones' : Lista de mapas que retorna Liquidacion.liquidar_todos, uno por confeccionista.
  """
  def totales(liquidaciones) do
    total_pagado = liquidaciones |> Enum.map(fn l -> l.neto end) |> Enum.sum()
    total_prendas = liquidaciones |> Enum.map(fn l -> l.prendas end) |> Enum.sum()

    promedio =
      if total_prendas == 0 do
        :no_calculable
      else
        total_pagado / total_prendas
      end

    %{total_pagado: total_pagado, total_prendas: total_prendas, promedio: promedio}
  end

  @doc """
  R7. Funcion que genera el reporte del total pagado por el taller y el costo promedio por prenda valida.

  Retorna:
  Un String con el titulo del reporte, el total que debe pagar el taller, el total de prendas validas
  y el costo promedio por prenda (o un mensaje indicando que no puede calcularse si no hay prendas validas).

  Parametros:
  - 'totales' : Mapa %{total_pagado, total_prendas, promedio} que retorna totales/1.
  """
  def reporte_r7(totales) do
    promedio =
      case totales.promedio do
        :no_calculable -> "no puede calcularse porque no hay prendas validas"
        valor -> "$#{Util.formater(valor)}"
      end

    "\n\n----------R7----------\nTotal que debe pagar el taller: $#{Util.formater(totales.total_pagado)}\nTotal de prendas validas: #{totales.total_prendas}\nCosto promedio por prenda valida: #{promedio}"
  end

  @doc """
  R8. Funcion que encuentra los confeccionistas que tuvieron al menos un lote valido en todas las
  lineas de produccion. La cantidad de lineas se obtiene del mapa de lineas, no esta escrita a mano.

  Retorna:
  Una lista de mapas %{codigo, nombre} ordenada por codigo, vacia si ninguno cumple.

  Parametros:
  - 'lotes_validos' : Lista de mapas con los lotes que pasaron la validacion.
  - 'lineas' : Mapa que contiene el id de la linea como clave y el mapa de la linea como valor.
  - 'confeccionistas' : Mapa que contiene el codigo del confeccionista como clave y el mapa del confeccionista como valor.
  """
  def en_todas_las_lineas(lotes_validos, lineas, confeccionistas) do
    # cantidad de lineas que existen, sin dejarla escrita a mano
    total_lineas = map_size(lineas)

    lotes_validos
    |> Enum.group_by(fn lote -> lote.confeccionista end)
    # me quedo con los que tienen tantas lineas distintas como lineas existen
    |> Enum.filter(fn {_codigo, lotes} ->
      lotes |> Enum.map(fn lote -> lote.linea end) |> Enum.uniq() |> length() == total_lineas
    end)
    |> Enum.map(fn {codigo, _lotes} ->
      %{codigo: codigo, nombre: Map.get(confeccionistas, codigo).nombre}
    end)
    |> Enum.sort_by(fn c -> c.codigo end)
  end

  @doc """
  R8. Funcion que genera el reporte de los confeccionistas que trabajaron en todas las lineas.

  Retorna:
  Un String con el titulo del reporte y un confeccionista por linea con su nombre y codigo,
  o un mensaje indicando que ninguno trabajo en todas las lineas si la lista esta vacia.

  Parametros:
  - 'confeccionistas' : Lista de mapas %{codigo, nombre} que retorna en_todas_las_lineas/3.
  """
  def reporte_r8(confeccionistas) do
    contenido =
      case confeccionistas do
        [] -> "Ningun confeccionista trabajo en todas las lineas"
        lista -> lista |> Enum.map(fn c -> "#{c.nombre} (#{c.codigo})" end) |> Enum.join("\n")
      end

    "\n\n----------R8----------\n#{contenido}"
  end

  @doc """
  Funcion que busca la liquidacion de un confeccionista a partir de su codigo.

  Retorna:
  - {:ok, liquidacion} : Si el codigo existe en las liquidaciones.
  - :error : Si el codigo no existe.

  Parametros:
  - 'liquidaciones' : Lista de mapas que retorna Liquidacion.liquidar_todos/2, uno por confeccionista.
  - 'codigo' : Codigo del confeccionista que se desea buscar.
  """
   def buscar_liquidacion(liquidaciones, codigo) do
    liquidaciones
    # me retorna un mapa con clave codigo, y valor el mapa de liquidacion completo
    |> Util.convertir_a_mapa_por(:codigo)
    |> Map.fetch(codigo)
  end

  @doc """
  Funcion que genera el comprobante individual de un confeccionista. Es pura: no imprime, solo arma el texto.
  Solo aparecen los dias con al menos un lote valido.

  Retorna:
  Un String con el nombre, el codigo, el detalle de cada dia trabajado (prendas, valor de los lotes y
  bonificacion diaria), la suma de lotes, la suma de bonificaciones, el descuento por alquiler y el neto a pagar.
  Si el confeccionista no tiene lotes validos, el detalle indica que no tiene dias trabajados.

  Parametros:
  - 'liquidacion' : Mapa con la liquidacion de un confeccionista, que retorna Liquidacion.liquidar_confeccionista/2.
  """
  def comprobante(liquidacion) do
    # liquidacion.detalle solo tiene los dias con al menos un lote valido, por eso no hace falta filtrar
    # se ordena por dia para garantizar que salgan en orden
    # retorna una lista de mapas, un mapa por cada dia
    detalle =
      case Enum.sort_by(liquidacion.detalle, fn d -> d.dia end) do
        # un confeccionista sin lotes validos tiene el detalle vacio
        [] ->
          "    Sin dias trabajados: no tiene lotes validos\n"

        dias ->
          dias
          # mapea la lista de mapas donde d, es un mapa que representa un dia de trabajo del confeccionista y recopila toda la info
          |> Enum.map(fn d ->
            "    Dia #{d.dia}:\n        prendas: #{d.prendas}\n        valor de los lotes: $#{Util.formater(d.valor_lotes)}\n        bonificacion diaria: $#{Util.formater(d.bonificacion)}\n"
          end)
          |> Enum.join("\n")
      end

    "\n\n----------Comprobante individual----------\nNombre: #{liquidacion.nombre}\nCodigo: #{liquidacion.codigo}\n\nDetalle por dia:\n#{detalle}\nSuma de lotes: $#{Util.formater(liquidacion.bruto)}\nSuma de bonificaciones: $#{Util.formater(liquidacion.bonificaciones)}\nDescuento por alquiler: $#{Util.formater(liquidacion.alquiler)}\nNeto a pagar: $#{Util.formater(liquidacion.neto)}"
  end

  @doc """
  C.1. Funcion que genera un ranking de las liquidaciones configurable mediante una keyword list.
  Las opciones son todas opcionales:
  - 'campo' : :neto (por defecto), :prendas o :bruto. Valor por el que se ordena.
  - 'orden' : :desc (por defecto) o :asc. De mayor a menor o de menor a mayor.
  - 'limite' : Entero positivo. Cantidad de confeccionistas a retornar (por defecto todos).
  Si una clave esta repetida se usa la primera (campo: :prendas, campo: :neto ordena por :prendas).

  Retorna:
  - {:ok, lista} : Lista de liquidaciones ordenadas segun las opciones y recortada si hay limite.
  - {:error, {:campo_invalido, valor}} : El campo no es :neto, :prendas ni :bruto.
  - {:error, {:orden_invalido, valor}} : El orden no es :desc ni :asc.
  - {:error, {:limite_invalido, valor}} : El limite no es un entero positivo.
  - {:error, :opciones_invalidas} : Las opciones no son una lista.

  Parametros:
  - 'liquidaciones' : Lista de mapas que retorna Liquidacion.liquidar_todos/2, uno por confeccionista.
  - 'opciones' : Keyword list con las opciones descritas anteriormente.
  """
  def ranking(_liquidaciones, opciones) when not is_list(opciones) do
    # si no es una lista (por ejemplo un mapa) Keyword.get fallaria, por eso se controla primero
    {:error, :opciones_invalidas}
  end

  # liquidaciones entra como una lista de mapas, opciones entra como una lista de keyword list con las opciones solicitadas
  def ranking(liquidaciones, opciones) do
    # with encadena las tres validaciones: si alguna retorna {:error, _} se devuelve ese error
    # y no se ejecuta lo que sigue (la misma idea que Validacion.validar_lote/3)
    # intenta asignar el atomo ingresado a la variable campo
    with {:ok, campo} <- opcion_campo(opciones),
         {:ok, orden} <- opcion_orden(opciones),
         {:ok, limite} <- opcion_limite(opciones) do
      # el campo elegido es la clave del mapa de cada liquidacion (:neto, :prendas o :bruto)
      # los ordena teniendo en cuenta el campo y si es asc o desc
      ordenadas =
        Enum.sort_by(liquidaciones, fn liquidacion -> Map.get(liquidacion, campo) end, orden)

      # retorna un tupla con :ok y la lista de datos
      {:ok, aplicar_limite(ordenadas, limite)}
    end
  end

  # Keyword.get/3 busca la clave y, si no existe, retorna el valor por defecto (el tercer argumento)
  # Si la clave esta repetida retorna la PRIMERA (campo: :prendas, campo: :neto usa :prendas)
  # opciones entre como una lista de keyword list
  defp opcion_campo(opciones) do
    # intenta extraer el valor de asociado al atomo :campo, si no es posible le asigna el valor por defecto ":neto"
    case Keyword.get(opciones, :campo, :neto) do
      # en un case valida que si se ingrese una de las trs opciones posibles para la clave campo
      campo when campo in [:neto, :prendas, :bruto] -> {:ok, campo}
      # en cualquier otro caso me retorna la tupla con el error, el tipo de error y el atomo que no se encontro
      otro -> {:error, {:campo_invalido, otro}}
    end
  end

  defp opcion_orden(opciones) do
    case Keyword.get(opciones, :orden, :desc) do
      orden when orden in [:desc, :asc] -> {:ok, orden}
      otro -> {:error, {:orden_invalido, otro}}
    end
  end

  # sin el valor por defecto Keyword.get retorna nil, y nil significa "sin limite"
  defp opcion_limite(opciones) do
    case Keyword.get(opciones, :limite) do
      nil -> {:ok, nil}
      limite when is_integer(limite) and limite > 0 -> {:ok, limite}
      otro -> {:error, {:limite_invalido, otro}}
    end
  end

  # en caso de que no tenga limite me retorna todos los valores obtenidos
  defp aplicar_limite(lista, nil), do: lista

  # caso contrario, que si tiene limite, toma los primeros "limite" elementos de los valores obtemidos
  defp aplicar_limite(lista, limite), do: Enum.take(lista, limite)

  @doc """
  C.1 (texto). Funcion que genera el reporte del ranking a partir del resultado de ranking/2.

  Retorna:
  Un String con un encabezado que muestra las opciones usadas, seguido de cada confeccionista con su posicion,
  nombre, codigo, prendas, bruto y neto. Si el resultado es un error, retorna el encabezado con el motivo.

  Parametros:
  - 'resultado' : La tupla {:ok, lista} o {:error, motivo} que retorna ranking/2.
  - 'opciones' : Keyword list usada en la consulta, se muestra en el encabezado.
  """
  def reporte_ranking_c1(resultado, opciones) do
    encabezado = "\n\n----------C.1 ranking(liquidaciones, #{inspect(opciones)})----------\n"

    case resultado do
      {:ok, lista} ->
        cuerpo =
          lista
          # index para organizarlo bonito en el string
          |> Enum.with_index(1)
          # le ingresa una lista de tuplas al map
          |> Enum.map(fn {x, posicion} ->
            "#{posicion}. #{x.nombre} (#{x.codigo})\n    prendas: #{x.prendas}\n    bruto: #{Util.formater(x.bruto)}\n    neto: #{Util.formater(x.neto)}\n"
          end)
          # join para separar cada puesto del ranking con un salto de linea
          |> Enum.join("\n")

        # junta el titulo con el rankin
        encabezado <> cuerpo

      {:error, motivo} ->
        # inspect vuelve la tupla en un string para agregarlo a mi string final
        encabezado <> "Opciones invalidas: #{inspect(motivo)}"
    end
  end

 @doc """
  C.2. Funcion que combina la produccion diaria del taller con la de un taller aliado usando Map.merge/3.
  Los dias presentes en ambos mapas suman sus prendas; los dias presentes en un solo mapa se copian sin cambios.

  Retorna:
  Un mapa %{dia => prendas} con la produccion combinada de ambos talleres.

  Parametros:
  - 'produccion_propia' : Mapa %{dia => prendas} del taller propio, que retorna produccion_por_dia/1.
  - 'produccion_aliada' : Mapa %{dia => prendas} informado por el taller aliado.
  """
  def combinar_talleres(produccion_propia, produccion_aliada) do
    # retorna un solo mapa con {dia => prendas mias + prendas del otro taller ese dia}
    Map.merge(produccion_propia, produccion_aliada, fn _dia, prendas_propias, prendas_aliadas ->
      prendas_propias + prendas_aliadas
    end)
  end

  @doc """
  C.2 (texto). Funcion que genera el reporte de la produccion combinada con el taller aliado.

  Retorna:
  Un String con un bloque por cada dia presente en alguno de los talleres, que muestra la produccion del taller
  propio, la del aliado ("-" si no informo ese dia), el resultado de Map.merge/3 (suma) y, solo para comparar,
  el de Map.merge/2 (el valor del segundo mapa reemplaza al del primero).

  Parametros:
  - 'produccion_propia' : Mapa %{dia => prendas} del taller propio.
  - 'produccion_aliada' : Mapa %{dia => prendas} del taller aliado.
  """
    def reporte_c2(produccion_propia, produccion_aliada) do
    combinado = combinar_talleres(produccion_propia, produccion_aliada)

    # este map merge/2 no suma los valores que tienen clave comun, simplemente escoje el valor asociado a la clave, pero dicho valor es el que sea el mayor de los dos mapas
    sin_sumar = Map.merge(produccion_propia, produccion_aliada)

    filas =
      combinado
      # me retorna una lista con todas las claves, es decir los dias
      |> Map.keys()
      # ordena esa lista de dias en orden de menor a mayor
      |> Enum.sort()
      |> Enum.map(fn dia ->
        # Map.get/3 con "-" para indicar que ese taller no informo ese dia
        "dia #{dia}:\n    taller propio: #{Map.get(produccion_propia, dia, "-")}\n    taller aliado: #{Map.get(produccion_aliada, dia, "-")}\n    combinado con Map.merge/3 (suma): #{Map.get(combinado, dia)}\n    con Map.merge/2 (no suma): #{Map.get(sin_sumar, dia)}\n"
      end)

      # el merge /3 me indica la suma de produccion de ambos talleres en un dia especifico, el map merge /2 me indica el taller que mas produjo de los dos en un dia especifico
      |> Enum.join("\n")

    "\n\n----------C.2 Produccion combinada con el taller aliado----------\n#{filas}"
  end
end
