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


  # R5 (calculo). Retorna una lista de 6 mapas (uno por dia) con la forma %{dia, prendas, lideres}
  # "lideres" es una lista con TODOS los confeccionistas que igualan el maximo de prendas ese dia.
  # Si "lideres" es una lista vacia significa que ese dia no hubo lotes validos
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

  # R5 (texto). Recibe la lista que entrega lideres_por_dia/1
  def reporte_r5(lideres_dias) do
    lineas =
      lideres_dias #lista de mapas
      |> Enum.map(fn dia -> #dia es un mapa
        case dia.lideres do
          [] -> "Dia #{dia.dia}:\n    sin lotes validos\n" #en caso de que no halla ningun lider por dia
          lideres -> "Dia #{dia.dia}:\n    lider: #{nombres_con_codigo(lideres)}\n    prendas: #{dia.prendas}\n" #si, si hay entonces agrega a la nueva lista un String con la informacion del lider de ese dia particular
        end
      end)
      |> Enum.join("\n") #juntamos todas las lineas donde cada linea es la informacion de un dia en particular

    "\n\n----------R5----------\n#{lineas}\n#{primer_lugar_mas_dias(lideres_dias)}" #acomodamos pa que quede bonito
  end

  # recibe una lista de mapas con :nombre y :codigo y los junta en un solo texto separado por comas
  defp nombres_con_codigo(personas) do
    personas
    |> Enum.map(fn persona -> "#{persona.nombre} (#{persona.codigo})" end)
    |> Enum.join(", ")
  end

  # indica quien ocupo el primer lugar mas dias y cuantos, si hay empate incluye a todos los empatados
  # (en un dia con empate, cada empatado suma un primer lugar)
  defp primer_lugar_mas_dias(lideres_dias) do #recibe lideres_dias que es una lista de mapas, un mapa por dia
    # una sola lista con todos los lideres de todos los dias
    todos_los_lideres = Enum.flat_map(lideres_dias, fn dia -> dia.lideres end) #me retorna una lista plana, donde salen los lideres de todos los dias, puede repetirse el confeccionista o los confeccionistas que liderarion varios dias
    # mapa con clave "codigo" y valor "cuantos dias fue lider"
    conteo = Enum.frequencies_by(todos_los_lideres, fn lider -> lider.codigo end) #como dije antes esta mapa que retorna el frequences tiene como clave el codigo del confeccionista y valor "cuentos dias fue lidel"
    # mapa para recuperar el nombre a partir del codigo
    nombres = Map.new(todos_los_lideres, fn lider -> {lider.codigo, lider.nombre} end) #este mapa es solo para obtener el nombre de los confeccionistas que lideraron

    case Map.values(conteo) do #esto me retorna una lista con elementos "veces que un confeccionista lidero" ej:[1,3,2]
      # si no hay ningun lider es porque ningun dia tuvo lotes validos
      [] ->
        "Ningun dia tuvo lotes validos, por lo que no hay primer lugar"

      veces_por_persona ->
        maximo = Enum.max(veces_por_persona) #em caso de que si halla una frecuencia en la lista ej:[1,2] miro cual fue el maximo, es decir la maxima cantidad de veces que alguien(confeccionista) lidero el dia.

        ganadores = #variable que
          conteo
          |> Enum.filter(fn {_codigo, veces} -> veces == maximo end) #filtro el, o la lista de los confeccionistas que tuvieron el maximo de dias en los que fue lider
          |> Enum.sort() #se organizan por orden alfabetico
          |> Enum.map(fn {codigo, _veces} -> %{codigo: codigo, nombre: Map.get(nombres, codigo)} end) #luego si busco el normbre y el codigo del confeccionista que tuvo la mayor frecuencia de lider por dia
          |> nombres_con_codigo() #le paso la lista de mapas a esta funcion que me devuelve todo acomodado en un string

        "Primer lugar en mas dias (#{maximo} dia(s)): #{ganadores}" #junto todo el mensaje que luego pasare a la funcion reporte_r5
    end
  end


  # R6. Retorna {:ok, mejores, elegibles} o {:error, :sin_elegibles}
  # elegibles son los que tienen al menos 3 lotes validos, ordenados del mejor al peor porcentaje ponderado
  # mejores son todos los que igualan el menor porcentaje ponderado (por si hay empate)
  def mejor_calidad(lotes_validos, confeccionistas) do
    elegibles =
      lotes_validos
      # mapa con clave "codigo del confeccionista" y valor "lista de sus lotes validos"
      |> Enum.group_by(fn lote -> lote.confeccionista end) #convertimos la lista de lotes validos, a un mapa que asocia una clave "codigo del confec" con un valor "lote valido de ese confec"
      # solo participan los que tienen al menos 3 lotes validos
      |> Enum.filter(fn {_codigo, lotes} -> length(lotes) >= 3 end) #pues de todo el mapa se filtran los que tengan una lista de 3, es decir que tenga al menos 3 lotes vlaidos
      |> Enum.map(fn {codigo, lotes} -> #esto me retorna una lista de mapas con la informacion de los confeccionistas que son elegibles para este reporte
        %{
          codigo: codigo,
          nombre: Map.get(confeccionistas, codigo).nombre,
          lotes: length(lotes),
          ponderado: porcentaje_ponderado(lotes),
          simple: porcentaje_simple(lotes)
        }
      end)
      |> Enum.sort_by(fn e -> {e.ponderado, e.codigo} end) #se ordenan segun el ponderado que obtuvieron y su codigo

    # este case me permite ver si hay elegibles y que pueda controlar un error en caso de que no
    case elegibles do
      [] ->
        {:error, :sin_elegibles} #error controlado en caso de que este reporte no tenga gente elegible

      [primero | _resto] -> #le asigna el primer elemento que tenia la lista de elegibles a la variable primero, es decir el que tuvo, o los que tuvieron el menor porcentaje ponderado de defectos. sin embargo toda la expresion [primero | _resto] significa una lista de mapas en este contexot
        mejores = Enum.filter(elegibles, fn e -> e.ponderado == primero.ponderado end) #retorna una lista de el que tuvo, o los que tuvieron el menor procentaje de defectos
        {:ok, mejores, elegibles} #finalmente me retorna un :ok para asegurarse de que si se completo la operacion, una lista de mapas con los mejores en calidad, y la lista de los que eran elegibles, esta ultima lista significa los confeccionistas que tenian al menos tres lotes validos
    end
  end

  # R6 (texto). Dos cabezas de funcion segun lo que retorne mejor_calidad/2
  def reporte_r6({:error, :sin_elegibles}) do
    "\n\n----------R6----------\nNingun confeccionista tiene al menos 3 lotes validos"
  end

  def reporte_r6({:ok, mejores, elegibles}) do
    ganadores = #variable que va a contener un string con el, o los que tuvieron el menor porcentaje de defectos
      mejores
      |> Enum.map(fn m -> #acomoda el string mapeando el o los ganadores
        "#{m.nombre} (#{m.codigo}) con #{Util.formater(m.ponderado)} % de defectos ponderado"
      end)
      |> Enum.join("\n")

    # muestra a todos los elegibles con ambas medidas para poder ver la diferencia entre ponderado y promedio simple
    comparacion = #esta variable contiene los que tenian al menos tres lotes validos.
      elegibles
      |> Enum.map(fn e ->
        "#{e.nombre} (#{e.codigo})\n    lotes: #{e.lotes}\n    defectos ponderado: #{Util.formater(e.ponderado)} %\n    defectos promedio simple: #{Util.formater(e.simple)} %\n"
      end)
      |> Enum.join("\n")

    "\n\n----------R6----------\nMejor calidad:\n#{ganadores}\n\nComparacion entre ponderado y promedio simple:\n#{comparacion}" #organizo el string pa q se vea bonito y ya
  end

  # porcentaje_ponderado = suma(defectos * prendas) / suma(prendas), esta sera la formula que usaremos para sabe el protentaje ponderado
  defp porcentaje_ponderado(lotes) do #recibe una lista de lotes, que es una lista de mapas
    defectos_por_prendas =
      lotes |> Enum.map(fn lote -> lote.defectos * lote.prendas end) |> Enum.sum() #cada lote es una mapa, el map retorna una lista de todos los dectos por prendas juntos en un elemento, luego el sum, suma todos los valores obtenidos

    prendas = lotes |> Enum.map(fn lote -> lote.prendas end) |> Enum.sum() #simplemente sumamos todas las prendas de los lotes

    defectos_por_prendas / prendas #hallamos el porcentaje ponderado de todos los lotes
  end

  # promedio simple de los porcentajes de defectos de cada lote
  defp porcentaje_simple(lotes) do #recibe una lista de mapas, donde cada mapa es un lote
    suma_defectos = lotes |> Enum.map(fn lote -> lote.defectos end) |> Enum.sum() #el map retorna una lista con todos los defectos de todos los los lotes, el sum, suma todos esos valores para quedar con un unico valor
    suma_defectos / length(lotes) #la formula para hallar el promedio simple
  end



  # R7 (calculo). Retorna un mapa con el total pagado, el total de prendas y el promedio
  # el promedio es :no_calculable cuando no hay prendas validas (evita dividir por cero)
  def totales(liquidaciones) do #liquidaciones es una lista de mapas que contiene la informacion de liquidacion de los confeccionistas
    total_pagado = liquidaciones |> Enum.map(fn l -> l.neto end) |> Enum.sum() #cacula la suma de lo que se le pago netamente a cada uno de los confeccionistas
    total_prendas = liquidaciones |> Enum.map(fn l -> l.prendas end) |> Enum.sum()#cacula la suma de todas las prendas que tienen cada uno de los confeccionistas

    promedio = #variable para calcular el promedio
      if total_prendas == 0 do
        :no_calculable #si no hay prendas, no puedo dividir entre cero obiamente
      else
        total_pagado / total_prendas #calcula el promediesito
      end

    %{total_pagado: total_pagado, total_prendas: total_prendas, promedio: promedio}
  end

  # R7 (texto)
  def reporte_r7(totales) do #recibe el mapa con la informacion para hacer el string
    promedio =
      case totales.promedio do #usa el case para hacer un mensaje bonito en caso de que no pueda calcularse el promedio
        :no_calculable -> "no puede calcularse porque no hay prendas validas"
        valor -> "$#{Util.formater(valor)}" #En caso de que si haya un promedio, entonces se lo asigna a la variable promedio
      end

    "\n\n----------R7----------\nTotal que debe pagar el taller: $#{Util.formater(totales.total_pagado)}\nTotal de prendas validas: #{totales.total_prendas}\nCosto promedio por prenda valida: #{promedio}" #el reporte acomodadito
  end


  # R8 (calculo). Retorna una lista de mapas %{codigo, nombre}, vacia si ninguno cumple
  # para los confeccionistas que tiene al menos un solo lote valido
  def en_todas_las_lineas(lotes_validos, lineas, confeccionistas) do #lineas y confeccionistas entran como un mapa que indexamos previamente en el main
    # cantidad de lineas que existen, sin dejarla escrita a mano
    total_lineas = map_size(lineas) #la cantidad de lineas que hay en los datos
    lotes_validos
    |> Enum.group_by(fn lote -> lote.confeccionista end) #retorna un mapa con calve "codigo del confeccionista" valor "lotes validos de ese confeccionista"
    # me quedo con los que tienen tantas lineas distintas como lineas que existen en los datos
    |> Enum.filter(fn {_codigo, lotes} -> #aqui agarro la lista de lotes (lista de mapas) y la mapeo de tal manera que el map me retorne una lista con los id de las lineas en las que opero un confeccionista, el uniq me retorna otra lista con los id de las lineas sin repedirse dicho id
      lotes |> Enum.map(fn lote -> lote.linea end) |> Enum.uniq() |> length() == total_lineas # el length me retorna cuando elementos hay en la lista que retorno uqnic, y finalmente comparamos si la cantidas de lineas en las que trabajo un confeccionista es igual a todas las lineas que existen en los datos
    end)
    |> Enum.map(fn {codigo, _lotes} -> #luego el resultado del filter, me retorna ya sea un mapa vacio o un mapa con clave "el codigo del confeccionista que si produjo un lote valido en todas las lineas" y valor "lotes que produjo (lista de mapas)"
      %{codigo: codigo, nombre: Map.get(confeccionistas, codigo).nombre} #este map me organiza el mapa que retorno filter emn una lista de mapas, donde cada mapa va a ser un confeccionista que tiene al menos un lote valido en todas las lineas
    end)
    |> Enum.sort_by(fn c -> c.codigo end) #organizo los mapas de los confeccionistas segun su codigo en orden alfabetico
  end

  # R8 (texto)
  def reporte_r8(confeccionistas) do #para generar el string bonito que se imprima en consola
    contenido =
      case confeccionistas do #confeccionistas es la lista de mapas con los confeccionistas que tiene al menos un lote valido en todas las lineas
        [] -> "Ningun confeccionista trabajo en todas las lineas" #en caso de que la lista este vacia, significa que ningun confeccionista trabajo en todas las lineas
        lista -> lista |> Enum.map(fn c -> "#{c.nombre} (#{c.codigo})" end) |> Enum.join("\n") #en caso de que si halla una lista con elementos (mapas) organizamos el string
      end

    "\n\n----------R8----------\n#{contenido}" #retornamos el string organizado
  end


  #comprobante individual
  # Busca la liquidacion de un confeccionista por su codigo.
  # Convierte la lista de liquidaciones en un mapa indexado por codigo (como se hace con los confeccionistas)
  # Map.fetch/2 retorna {:ok, liquidacion} si el codigo existe, o :error si no existe (sin lanzar excepcion)
  def buscar_liquidacion(liquidaciones, codigo) do
    liquidaciones
    |> Util.convertir_a_mapa_por(:codigo) #me retorna un mapa con clave codigo, y valor el mapa de liquidacion completo
    |> Map.fetch(codigo)
  end

  # Recibe la liquidacion de UN confeccionista (el mapa que arma Liquidacion.liquidar_confeccionista/2)
  # y retorna el texto del comprobante. Es pura: no imprime, solo arma el string
  def comprobante(liquidacion) do #liquidacion entra como un mapa
    # liquidacion.detalle solo tiene los dias con al menos un lote valido, por eso no hace falta filtrar
    # se ordena por dia para garantizar que salgan en orden
    detalle =
      case Enum.sort_by(liquidacion.detalle, fn d -> d.dia end) do #retorna una lista de mapas, un mapa por cada dia
        # un confeccionista sin lotes validos tiene el detalle vacio
        [] ->
          "    Sin dias trabajados: no tiene lotes validos\n"

        dias ->
          dias
          |> Enum.map(fn d -> #mapea la lista de mapas donde d, es un mapa que representa un dia de trabajo del confeccionista y recopila toda la info
            "    Dia #{d.dia}:\n        prendas: #{d.prendas}\n        valor de los lotes: $#{Util.formater(d.valor_lotes)}\n        bonificacion diaria: $#{Util.formater(d.bonificacion)}\n"
          end)
          |> Enum.join("\n")
      end

    "\n\n----------Comprobante individual----------\nNombre: #{liquidacion.nombre}\nCodigo: #{liquidacion.codigo}\n\nDetalle por dia:\n#{detalle}\nSuma de lotes: $#{Util.formater(liquidacion.bruto)}\nSuma de bonificaciones: $#{Util.formater(liquidacion.bonificaciones)}\nDescuento por alquiler: $#{Util.formater(liquidacion.alquiler)}\nNeto a pagar: $#{Util.formater(liquidacion.neto)}"
  end

  # C1
  # Recibe la lista de liquidaciones y una keyword list con estas opciones (todas opcionales):
  #   campo:  :neto (por defecto), :prendas o :bruto   -> por que valor se ordena
  #   orden:  :desc (por defecto) o :asc               -> de mayor a menor o de menor a mayor
  #   limite: entero positivo (por defecto todos)      -> cuantos confeccionistas se devuelven
  # Retorna {:ok, lista} o {:error, motivo} si alguna opcion tiene un valor invalido
  def ranking(_liquidaciones, opciones) when not is_list(opciones) do
    # si no es una lista (por ejemplo un mapa) Keyword.get fallaria, por eso se controla primero
    {:error, :opciones_invalidas}
  end

  def ranking(liquidaciones, opciones) do #liquidaciones entra como una lista de mapas, opciones entra como una lista de keyword list con las opciones solicitadas
    # with encadena las tres validaciones: si alguna retorna {:error, _} se devuelve ese error
    # y no se ejecuta lo que sigue (la misma idea que Validacion.validar_lote/3)
    with {:ok, campo} <- opcion_campo(opciones), #intenta asignar el atomo ingresado a la variable campo
         {:ok, orden} <- opcion_orden(opciones),
         {:ok, limite} <- opcion_limite(opciones) do
      ordenadas =
        # el campo elegido es la clave del mapa de cada liquidacion (:neto, :prendas o :bruto)
        Enum.sort_by(liquidaciones, fn liquidacion -> Map.get(liquidacion, campo) end, orden) #los ordena teniendo en cuenta el campo y si es asc o desc

      {:ok, aplicar_limite(ordenadas, limite)} #retorna un tupla con :ok y la lista de datos
    end
  end

  # Keyword.get/3 busca la clave y, si no existe, retorna el valor por defecto (el tercer argumento)
  # Si la clave esta repetida retorna la PRIMERA (campo: :prendas, campo: :neto usa :prendas)
  defp opcion_campo(opciones) do #opciones entre como una lista de keyword list
    case Keyword.get(opciones, :campo, :neto) do #intenta extraer el valor de asociado al atomo :campo, si no es posible le asigna el valor por defecto ":neto"
      campo when campo in [:neto, :prendas, :bruto] -> {:ok, campo} #en un case valida que si se ingrese una de las trs opciones posibles para la clave campo
      otro -> {:error, {:campo_invalido, otro}} #en cualquier otro caso me retorna la tupla con el error, el tipo de error y el atomo que no se encontro
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

  defp aplicar_limite(lista, nil), do: lista #en caso de que no tenga limite me retorna todos los valores obtenidos
  defp aplicar_limite(lista, limite), do: Enum.take(lista, limite) #caso contrario, que si tiene limite, toma los primeros "limite" elementos de los valores obtemidos

  # C.1 (texto). Recibe lo que retorna ranking/2 y las opciones usadas, para mostrarlas en el titulo
  def reporte_ranking_c1(resultado, opciones) do
    encabezado = "\n\n----------C.1 ranking(liquidaciones, #{inspect(opciones)})----------\n"

    case resultado do
      {:ok, lista} ->
        cuerpo =
          lista
          |> Enum.with_index(1) #index para organizarlo bonito en el string
          |> Enum.map(fn {x, posicion} -> #le ingresa una lista de tuplas al map
            "#{posicion}. #{x.nombre} (#{x.codigo})\n    prendas: #{x.prendas}\n    bruto: #{Util.formater(x.bruto)}\n    neto: #{Util.formater(x.neto)}\n"
          end)
          |> Enum.join("\n") #join para separar cada puesto del ranking con un salto de linea

        encabezado <> cuerpo #junta el titulo con el rankin

      {:error, motivo} ->
        encabezado <> "Opciones invalidas: #{inspect(motivo)}" #inspect vuelve la tupla en un string para agregarlo a mi string final
    end
  end

  #C2
  # Recibe dos mapas %{dia => prendas} y los combina sumando las prendas de los dias presentes en ambos
  # Map.merge/3 llama a la funcion SOLO cuando la clave (el dia) esta en los dos mapas.
  # Si el dia esta en un solo mapa, se copia tal cual (por eso el dia 7 queda con 200)
  def combinar_talleres(produccion_propia, produccion_aliada) do #recibe produccion propia y aliada cada una como un mapa con dia ,prendas
    Map.merge(produccion_propia, produccion_aliada, fn _dia, prendas_propias, prendas_aliadas -> #retorna un solo mapa con {dia => prendas mias + prendas del otro taller ese dia}
      prendas_propias + prendas_aliadas
    end)
  end

  # C.2 (texto). Muestra dia por dia lo que produjo cada taller, el resultado de Map.merge/3
  # y, solo para comparar, el resultado de Map.merge/2 (que no suma: el segundo mapa pisa al primero)
  def reporte_c2(produccion_propia, produccion_aliada) do
    combinado = combinar_talleres(produccion_propia, produccion_aliada)
    sin_sumar = Map.merge(produccion_propia, produccion_aliada) #este map merge/2 no suma los valores que tienen clave comun, simplemente escoje el valor asociado a la clave, pero dicho valor es el que sea el mayor de los dos mapas

    filas =
      combinado
      |> Map.keys() #me retorna una lista con todas las claves, es decir los dias
      |> Enum.sort() #ordena esa lista de dias en orden de menor a mayor
      |> Enum.map(fn dia ->
        # Map.get/3 con "-" para indicar que ese taller no informo ese dia
        "dia #{dia}:\n    taller propio: #{Map.get(produccion_propia, dia, "-")}\n    taller aliado: #{Map.get(produccion_aliada, dia, "-")}\n    combinado con Map.merge/3 (suma): #{Map.get(combinado, dia)}\n    con Map.merge/2 (no suma): #{Map.get(sin_sumar, dia)}\n"
      end) #el merge /3 me indica la suma de produccion de ambos talleres en un dia especifico, el map merge /2 me indica el taller que mas produjo de los dos en un dia especifico
      |> Enum.join("\n")

    "\n\n----------C.2 Produccion combinada con el taller aliado----------\n#{filas}"
  end
end
