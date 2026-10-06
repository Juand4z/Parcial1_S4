defmodule Liquidacion do
  @moduledoc """
  Modulo encargado de la liquidacion de los confeccionistas del taller.
  Calcula el valor de cada lote segun su porcentaje de defectos, las bonificaciones
  diarias, el descuento por alquiler de máquinas y el pago neto de cada confeccionista.
  - Autores: Luis Miguel Garcia Villanueva, Juan David Arias Sanchez.
  - Fecha: Octubre 5 2026
  - Licencia: GNU GPL v3
  """

  @doc """
  Funcion calcula el valor de un lote con respecto a sus prendas y porcentaje de defectos.
  Retorna un flotante o real que representa el valor total del lote calculado
  Parametros:
  - 'lote' : Mapa base que contiene las claves prendas y defectos.
  - 'prendas: prendas,' : Representa la cantidad de prendas de el lote (Pattern Matching).
  - 'defectos : defectos' : Representa el porcentaje de defectos dentro del lote (Pattern Matching).
  """
  def valor_lote(%{prendas: prendas, defectos: defectos}) do
    prendas * 32 * ajuste_defecto(defectos)
  end

  defp ajuste_defecto(defectos) when defectos <= 2, do: 107
  defp ajuste_defecto(defectos) when defectos > 2 and defectos <= 5, do: 100
  defp ajuste_defecto(defectos) when defectos > 5 and defectos <= 10, do: 88
  defp ajuste_defecto(_defectos), do: 75

  @doc """
  Funion que calcula una bonificacion segun la cantidad de prendas realizadas en un lote.

  Retorna: Una bonificacion de 18000 si la cantidad de prendas es mayor o igual a 120.

  Parametros:
  - 'prendas_dia' : Cantidad de prendas realizadas en un lote
  """
  def bonificacion_del_dia(prendas_dia) do
    if prendas_dia >= 120 do
      18000
    else
      0
    end
  end

  @doc """
  Funcion que descuenta el costo del alquier en funcion de la cantidad de dias utilizados.

  Retorna: El valor total del descuento realizado segun los dias que se utilizo.

  Parametros:
  - '{alquiler: true}' : Tupla que indica si el confeccionista utilizo el alquiler de maquinas.
  - 'dias' : Cantidad de dias registrados del alquiler de la maquina.
  """
  def alquiler_maquina_descontable(%{alquiler: true}, dias) do
    dias * 15000
  end

  @doc """
  Funcion que descuenta el costo del alquier en funcion de la cantidad de dias utilizados.

  Retorna 0, el confeccionista no utilizo el alquiler de maquinas.

  Parametros:
  - '{alquiler: true}' : Tupla que indica si el confeccionista utilizo el alquiler de maquinas (se ignora en este caso).
  - 'dias' : Cantidad de dias registrados del alquiler de la maquina (se ignora en este caso ).
  """
  def alquiler_maquina_descontable(_confeccionista, _dias), do: 0

  @doc """
  Funcion que realiza la liquidacion total de un confeccionista respecto a sus lotes validos realizados.

  Retorna: Un mapa con la siguiente estructura:
  - 'codigo' : Identificacion del confeccionista.
  - 'nombre' : Nombre del confeccionista.
  - 'prendas' : Total de prendas realizadas por el confeccionista.
  - 'bruto' : Valor total acumulado de los lotes de todos los diad trabajados.
  - 'bonificaciones': Suma total de las bonificaciones o descuentons respectivamente.
  - 'alquiler' : Valor a descontar por el alquiler de las maquinas (en caso de que aplique).
  - 'neto': Pago total final.
  - 'detalle' : Lista con el trabajo diario realizado.

  Parametros:
  - 'confeccinista': Mapa con la informacion del confeccionista validada.
  - 'lotes_validos': Lista de mapas de los lotes validados.
  """
  def liquidar_confeccionista(confeccionista, lotes_validos) do
    # detalle representa un mapa que se define en la funcion detalle_del_dia() con diferentes claves que se ven en esa funcion
    detalle =
      lotes_validos
      # Se agrupan por dia en otro mapa donde el dia representara la clave y un alista de lotes el valor
      |> Enum.group_by(fn lote -> lote.dia end)
      # Se ordenan teniendo en cuenta el dia es decir cornologicamente
      |> Enum.sort_by(fn {dia, _lotes} -> dia end)
      # Paso el ultimo mapa obtenido a un Enum.map para pasar cada dia por la funcion detalle_del_dia()
      |> Enum.map(fn {dia, lotes_del_dia} -> detalle_del_dia(dia, lotes_del_dia) end)

    # reprensenta el valor bruto de los lotes en un dia sumando el valor de los lotes del confeccionista sin importar el dia
    bruto =
      Enum.map(detalle, fn detalle_dia -> Map.get(detalle_dia, :valor_lotes) end) |> Enum.sum()

    # representa el valore de la bonificacion del confeccionista sumando 18k por cada dia que supere 120 prendas
    bonificaciones =
      Enum.map(detalle, fn detalle_dia -> Map.get(detalle_dia, :bonificacion) end) |> Enum.sum()

    # calcula cuanto fue el costo del alquiler para descontarselo luego al confeccionista
    alquiler = alquiler_maquina_descontable(confeccionista, length(detalle))

    %{
      # confeccionista es un mapa por eso se usa .codigo, .nombre, etc
      codigo: confeccionista.codigo,
      nombre: confeccionista.nombre,
      # recorre la lista de mapas "detalle" para sumar las prendas de cada dia que tuvo un confeccionista
      prendas: Enum.map(detalle, fn x -> Map.get(x, :prendas) end) |> Enum.sum(),
      bruto: bruto,
      bonificaciones: bonificaciones,
      alquiler: alquiler,
      neto: bruto + bonificaciones - alquiler,
      detalle: detalle
    }
  end

  @doc """

     Funcion que realiza el detalle en funcion de un dia.

   ## Retorna: Un mapa con la siguiente estructura
   - 'dia' : Numero del dia.
   - 'prendas' : Prendas totales del dia.
   - 'valor_lotes' : Acumulado total del valor de los lotes del dia.
   - 'bonificacion' : Bonificacion obtenida segun las prendas acumuladas.

  ### Parametros:

  - 'dia' : Dia trabajado (Valor del 1 a 6).
  - 'lotes_del_dia' : Lista de mapas con los lotes segun el dia.


  """
  defp detalle_del_dia(dia, lotes_del_dia) do
    prendas =
      Enum.map(lotes_del_dia, fn lote -> Map.get(lote, :prendas) end)
      |> Enum.sum()

    %{
      dia: dia,
      prendas: prendas,
      valor_lotes: lotes_del_dia |> Enum.map(fn x -> valor_lote(x) end) |> Enum.sum(),
      bonificacion: bonificacion_del_dia(prendas)
    }
  end

  @doc """
   Funcion que liquida a todos los confeccionistas registrados validados.
   Retorna: Lista de mapas donde cada elemento representa la liquidacion indivual de un confeccionista.

   Parametros:
   - 'confeccionistas' : Lista de mapas con los datos de todos los confeccionistas registrados validados.
   - 'lotes_validados' : Lista de mapas con los lotes validos totales.


  """
  # lotes validos entran como una lista de mapas
  def liquidar_todos(confeccionistas, lotes_validos) do
    # crea un mapa con clave "el codigo del confeccionista" y valor "los lotes validos de ese confeccionista"
    grupos = Enum.group_by(lotes_validos, fn lote -> lote.confeccionista end)

    confeccionistas
    # convierte el mapa de confeccionistas en una lista para poder recorrerla
    |> Map.values()
    # recorre dicha lista para ordenarla segun el codigo del confeccionista
    |> Enum.sort_by(fn confeccionista -> confeccionista.codigo end)
    # liquida cada confeccionista, resultando una lista de mapas, siendo cada mapa los del confeccionista junto con los datos de su liquidacion
    |> Enum.map(fn confeccionista ->
      # se usar Map.get/3 para q en caso de que un confeccionista no halla trabajo o no tenga lotes validos, la variable lotes_validos no tome el valor de "nil", sino que le asigne una lista vacia "[]" para hacer las operaciones matematicas sin problemas como Enum.sum([]) = 0
      liquidar_confeccionista(confeccionista, Map.get(grupos, confeccionista.codigo, []))
    end)
  end
end
