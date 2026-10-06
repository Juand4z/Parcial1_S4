defmodule Util do
  @moduledoc """
  Módulo con funciones que se reutilizan
  - Autor: Robinson Arias Muñoz.
  - Fecha: Septiembre del 2026
  - Licencia: GNU GPL v3
  """

  @doc """
  Función para mostrar un mensaje en la pantalla.
  ## Parámetros
   - mensaje, texto que se le presenta al usuario
  ## Ejemplos

    ```elixir
    iex> Util.mostrar_mensaje("Hola Mundo")
    ```

    o puede usar

    ```elixir
    "Hola Mundo"
    |> Util.mostrar_mensaje()
    ```
  """
  def mostrar_mensaje(mensaje) do
    mensaje
    |> IO.puts()
  end

  @doc """
  Función para mostrar un mensaje de error en la pantalla.
  ## Parámetros
   - mensaje, texto que se le presenta al usuario como error
  ## Ejemplos

    ```elixir
    iex> Util.mostrar_error("Dato inválido")
    ```

    o puede usar

    ```elixir
    "Dato inválido"
    |> Util.mostrar_error()
    ```
  """
  def mostrar_error(mensaje) do
    IO.puts(:standard_error, mensaje)
  end

  @doc """
  Función para ingresar un dato (:texto, :entero o :real) desde el teclado
  ## Parámetros
   - mensaje, texto que se le presenta al usuario
  ## Ejemplos

    ```elixir
    iex> Util.ingresar("Ingrese el nombre: ", :texto)
    ```
    ```elixir
    iex> Util.ingresar("Ingrese la edad: ", :entero)
    ```
   ```elixir
    iex> Util.ingresar("Ingrese la altura: ", :real)
    ```
    o puede usar

    ```elixir
    "Ingrese el nombre: "
    |> Util.ingresar(:texto)
    ```

    ```elixir
    "Ingrese la edad: "
    |> Util.ingresar(:entero)
    ```

    ```elixir
    "Ingrese la altura: "
    |> Util.ingresar(:real)
    ```
  """
  def ingresar(mensaje, :texto) do
    case IO.gets(mensaje) do
      texto when is_binary(texto) -> String.trim(texto)
      _ -> ""
    end
  end

  def ingresar(mensaje, :booleano) do
    valor =
      mensaje
      |> IO.gets()
      |> String.trim()
      |> String.downcase()

    if valor == "si" do
      true
    else
      false
    end
  end

  def ingresar(mensaje, :entero) do
    ingresar(
      mensaje,
      &String.to_integer/1,
      :entero
    )
  end

  def ingresar(mensaje, :real) do
    ingresar(
      mensaje,
      &String.to_float/1,
      :real
    )
  end

  # Función privada de apoyo para crear la lectura con validación de enteros y reales.
  defp ingresar(mensaje, parser, tipo_dato) do
    try do
      mensaje
      |> ingresar(:texto)
      |> parser.()
    rescue
      ArgumentError ->
        "Error, se espera que ingrese un número #{tipo_dato}\n"
        |> mostrar_error()

        mensaje
        |> ingresar(parser, tipo_dato)
    end
  end

  @doc """
  Funcion mejorada con IA para hacer que un valor numerico ya sea entero o float quede solo con dos decimales, esto puede ser util para mostrar numeros por
  consola sin la notacion de la terminal
  ## Parametros
   -valor, para convertirlo a dos decimales
  """
  def formater(valor) do
    # Si es entero, lo divide por 1 para volverlo float (ej. 529560 -> 529560.0)
    # Si ya es float, lo deja igual.
    float_valor = if is_integer(valor), do: valor / 1, else: valor

    :io_lib.format("~.2f", [float_valor])
    |> List.to_string()
  end

  def texto_a_entero(texto) do
    case Integer.parse(String.trim(texto)) do
      {n, ""} -> {:ok, n}
      _ -> :error
    end
  end

  @doc """
  Funcion generada con IA para pasar de una cadena de texto a un valor numerico que puede ser entero o float
  ## Parametros
   -valor, para convertirlo a dos decimales
  """
  def texto_a_numero(texto) do
    texto = String.trim(texto)

    case Integer.parse(texto) do
      {n, ""} ->
        {:ok, n}

      _ ->
        case Float.parse(texto) do
          {f, ""} -> {:ok, f}
          _ -> :error
        end
    end
  end

  @doc """
  funcion que convierte una lista de mapas en un solo mapa, indexado por el valor de una clave de cada elemento.
  Permite buscar un elemento por su codigo o id con Map.get/2 en lugar de recorrer la lista (ver mediciones.exs).
  Si dos elementos tienen el mismo valor en la clave, queda el ultimo.

  Retorna: Un mapa donde cada clave es el valor de 'clave' de un elemento y el valor es el elemento completo.

  ## Parametros
  - elementos, lista de mapas que se quiere indexar
  - clave, atomo con el nombre del campo que se usara como clave (ej. :codigo, :id)
  """
  def convertir_a_mapa_por(elementos, clave) do
    Map.new(elementos, fn elemento -> {Map.get(elemento, clave), elemento} end)
  end








  #funciones para validar datos erroneos, esto es para que no afecte las validaciones ni los resultados de las reglas de negocio
  #esta validacion se construyo usando la logica de la inteligencia artifial, la cual sugirio que filtraramos los datos antes de ingresarlos al programa
  #esto con el proposito de separar los errores de datos mal ingresados con los errores de las reglas de negocio




  @doc """
  Filtra la lista de confeccionistas que entrega Datos antes de usarla en el programa.
  Se descartan los elementos que no sean un mapa con 'codigo' (texto no vacio), 'nombre' (texto no vacio)
  y 'alquiler' (booleano), y los que repitan un codigo ya visto (se conserva el primero).

  Retorna: %{validos: lista, descartados: lista de tuplas {elemento, motivo}}.
  Los motivos son :estructura_invalida, :duplicado o :no_es_lista.
  """
  def filtrar_confeccionistas(elementos) do
    filtrar_unicos(elementos, :codigo, &confeccionista_valido?/1)
  end

  @doc """
  Filtra la lista de lineas que entrega Datos antes de usarla en el programa.
  Se descartan los elementos que no sean un mapa con 'id' (texto no vacio), 'nombre' (texto no vacio)
  y 'puestos' (entero positivo), y los que repitan un id ya visto (se conserva el primero).

  Retorna: %{validos: lista, descartados: lista de tuplas {elemento, motivo}}.
  """
  def filtrar_lineas(elementos) do
    filtrar_unicos(elementos, :id, &linea_valida?/1)
  end

  @doc """
  Filtra la lista de lotes que entrega Datos. Solo revisa la ESTRUCTURA: se descartan los elementos que no sean
  un mapa con las cinco claves (confeccionista, linea, dia, prendas, defectos). Los valores NO se revisan aqui:
  un lote con un dia, unas prendas o un porcentaje erroneos pasa este filtro y lo rechaza Validacion (y sale en el reportesito 1).

  Retorna: %{validos: lista, descartados: lista de tuplas {elemento, motivo}}.
  """
  def filtrar_lotes(elementos) when is_list(elementos) do
    %{
      validos: Enum.filter(elementos, &lote_con_estructura?/1),
      descartados:
        elementos
        |> Enum.reject(&lote_con_estructura?/1)
        |> Enum.map(fn elemento -> {elemento, :estructura_invalida} end)
    }
  end

  def filtrar_lotes(otro), do: %{validos: [], descartados: [{otro, :no_es_lista}]}

  # Recorre la lista una sola vez con Enum.reduce. El mapa 'vistos' guarda los identificadores ya aceptados
  # para detectar duplicados sin volver a recorrer la lista.
  defp filtrar_unicos(elementos, clave, es_valido?) when is_list(elementos) do
    {validos, descartados, _vistos} =
      Enum.reduce(elementos, {[], [], %{}}, fn elemento, {validos, descartados, vistos} ->
        cond do
          not es_valido?.(elemento) ->
            {validos, [{elemento, :estructura_invalida} | descartados], vistos}

          Map.has_key?(vistos, Map.get(elemento, clave)) ->
            {validos, [{elemento, :duplicado} | descartados], vistos}

          true ->
            {[elemento | validos], descartados, Map.put(vistos, Map.get(elemento, clave), true)}
        end
      end)

    %{validos: Enum.reverse(validos), descartados: Enum.reverse(descartados)}
  end

  defp filtrar_unicos(otro, _clave, _es_valido?), do: %{validos: [], descartados: [{otro, :no_es_lista}]}

  defp confeccionista_valido?(%{codigo: codigo, nombre: nombre, alquiler: alquiler})
       when is_binary(codigo) and codigo != "" and is_binary(nombre) and nombre != "" and
              is_boolean(alquiler),
       do: true

  defp confeccionista_valido?(_otro), do: false

  defp linea_valida?(%{id: id, nombre: nombre, puestos: puestos})
       when is_binary(id) and id != "" and is_binary(nombre) and nombre != "" and
              is_integer(puestos) and puestos > 0,
       do: true

  defp linea_valida?(_otro), do: false

  defp lote_con_estructura?(%{confeccionista: _, linea: _, dia: _, prendas: _, defectos: _}), do: true
  defp lote_con_estructura?(_otro), do: false
end
