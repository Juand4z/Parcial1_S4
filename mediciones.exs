# Punto C.3 - Medir en lugar de suponer.
#
# Este script es independiente del programa principal: no usa los demas
# modulos, asi que no hay que compilar nada. Se ejecuta con:
#
#     elixir medicion.exs
#
# Es un script IMPURO a proposito (imprime y mide el tiempo), por eso vive
# aparte de los modulos puros del programa (Validacion, Liquidacion, Reportes).
#
# Mide dos comparaciones, cada una @repeticiones veces:
#   1. Buscar 1.000 codigos en 100.000 confeccionistas: lista (Enum.find/2) vs mapa (Map.get/2)
#   2. Construir una lista de 20.000 elementos: agregando al final (++) vs al inicio ([x | lista])
#
# Los tiempos de :timer.tc/1 vienen en microsegundos (1 ms = 1.000 microsegundos).

defmodule Medicion do
  @repeticiones 5
  @cantidad_confeccionistas 100_000
  @cantidad_busquedas 1_000
  @cantidad_elementos 20_000

  def main do
    IO.puts("=== Datos del equipo (Intel Core Ultra 7 255U, 16gb ddr5 7447MT/s) ===")
    IO.puts("Elixir #{System.version()} / OTP #{:erlang.system_info(:otp_release)}")
    IO.puts("Procesadores logicos: #{:erlang.system_info(:logical_processors)}")
    IO.puts("Arquitectura: #{:erlang.system_info(:system_architecture)}")
    IO.puts("Repeticiones por medicion: #{@repeticiones}")

    busqueda_en_lista_y_mapa()
    construccion_de_listas()
  end

  # ---------------------------------------------------------------
  # Medicion 1: buscar por codigo en una lista vs en un mapa
  # ---------------------------------------------------------------
  defp busqueda_en_lista_y_mapa do
    IO.puts("\n=== Medicion 1: buscar #{@cantidad_busquedas} codigos entre #{@cantidad_confeccionistas} confeccionistas ===")

    # los 100.000 confeccionistas se generan con Enum.map sobre un rango
    lista =
      Enum.map(1..@cantidad_confeccionistas, fn n ->
        %{codigo: "C#{n}", nombre: "Confeccionista #{n}", alquiler: rem(n, 2) == 0} #los confeccionistas que son impares tiene el alquiler en false, caso contrario en true
      end)

    # el mismo conjunto, pero indexado por codigo (igual que Util.convertir_a_mapa_por/2 en el programa)
    mapa = Map.new(lista, fn confeccionista -> {confeccionista.codigo, confeccionista} end)

    # semilla fija: asi las 5 repeticiones (y las dos estructuras) buscan exactamente los mismos codigos
    :rand.seed(:exsss, {101, 102, 103}) #Esto garantiza que las 1.000 búsquedas aleatorias sean exactamente las mismas para la lista y para el mapa, haciendo que la competencia sea justa entre ambas estructuras.

    codigos =
      Enum.map(1..@cantidad_busquedas, fn _ -> "C#{:rand.uniform(@cantidad_confeccionistas)}" end)

    resultados =
      Enum.map(1..@repeticiones, fn intento ->
        tiempo_lista =
          medir(fn ->
            Enum.each(codigos, fn codigo ->
              Enum.find(lista, fn confeccionista -> confeccionista.codigo == codigo end)
            end)
          end)

        tiempo_mapa =
          medir(fn ->
            Enum.each(codigos, fn codigo -> Map.get(mapa, codigo) end)
          end)

        {intento, tiempo_lista, tiempo_mapa}
      end)

    IO.puts(columna("Intento", 9) <> columna_der("Lista Enum.find (us)", 22) <> columna_der("Mapa Map.get (us)", 20) <> columna_der("Lista/Mapa", 12))

    Enum.each(resultados, fn {intento, lista_us, mapa_us} ->
      IO.puts(columna(intento, 9) <> columna_der(lista_us, 22) <> columna_der(mapa_us, 20) <> columna_der("#{razon(lista_us, mapa_us)}x", 12))
    end)

    promedio_lista = promedio(Enum.map(resultados, fn {_, l, _} -> l end))
    promedio_mapa = promedio(Enum.map(resultados, fn {_, _, m} -> m end))

    IO.puts(columna("Promedio", 9) <> columna_der(promedio_lista, 22) <> columna_der(promedio_mapa, 20) <> columna_der("#{razon(promedio_lista, promedio_mapa)}x", 12))
  end

  # ---------------------------------------------------------------
  # Medicion 2: construir una lista agregando al final vs al inicio
  # ---------------------------------------------------------------
  defp construccion_de_listas do
    IO.puts("\n=== Medicion 2: construir una lista de #{@cantidad_elementos} elementos con Enum.reduce/3 ===")

    resultados =
      Enum.map(1..@repeticiones, fn intento ->
        # agregar al final: ++ recorre y copia TODA la lista acumulada en cada paso
        tiempo_final =
          medir(fn ->
            Enum.reduce(1..@cantidad_elementos, [], fn elemento, acumulado -> acumulado ++ [elemento] end)
          end)

        # agregar al inicio: [elemento | lista] no copia nada, solo crea una celda nueva
        tiempo_inicio =
          medir(fn ->
            Enum.reduce(1..@cantidad_elementos, [], fn elemento, acumulado -> [elemento | acumulado] end)
          end)

        # agregar al inicio y dar vuelta al final: la forma habitual si el orden importa
        tiempo_inicio_reverse =
          medir(fn ->
            1..@cantidad_elementos
            |> Enum.reduce([], fn elemento, acumulado -> [elemento | acumulado] end)
            |> Enum.reverse()
          end)

        {intento, tiempo_final, tiempo_inicio, tiempo_inicio_reverse}
      end)

    IO.puts(columna("Intento", 9) <> columna_der("Al final ++ (us)", 18) <> columna_der("Al inicio | (us)", 18) <> columna_der("Inicio + reverse (us)", 23) <> columna_der("++/inicio", 11))

    Enum.each(resultados, fn {intento, final_us, inicio_us, reverse_us} ->
      IO.puts(columna(intento, 9) <> columna_der(final_us, 18) <> columna_der(inicio_us, 18) <> columna_der(reverse_us, 23) <> columna_der("#{razon(final_us, inicio_us)}x", 11))
    end)

    promedio_final = promedio(Enum.map(resultados, fn {_, f, _, _} -> f end))
    promedio_inicio = promedio(Enum.map(resultados, fn {_, _, i, _} -> i end))
    promedio_reverse = promedio(Enum.map(resultados, fn {_, _, _, r} -> r end))

    IO.puts(columna("Promedio", 9) <> columna_der(promedio_final, 18) <> columna_der(promedio_inicio, 18) <> columna_der(promedio_reverse, 23) <> columna_der("#{razon(promedio_final, promedio_inicio)}x", 11))
  end

  # ---------------------------------------------------------------
  # Funciones de apoyo
  # ---------------------------------------------------------------

  # :timer.tc/1 ejecuta la funcion y retorna {microsegundos, resultado}; solo nos interesa el tiempo
  defp medir(funcion) do
    {microsegundos, _resultado} = :timer.tc(funcion)
    microsegundos
  end

  defp promedio(tiempos), do: div(Enum.sum(tiempos), length(tiempos))

  # cuantas veces es mas lento el primero que el segundo (max(.., 1) evita dividir por cero)
  defp razon(lento, rapido), do: Float.round(lento / max(rapido, 1), 1)

  defp columna(valor, ancho), do: valor |> to_string() |> String.pad_trailing(ancho)
  defp columna_der(valor, ancho), do: valor |> to_string() |> String.pad_leading(ancho)
end

Medicion.main()
