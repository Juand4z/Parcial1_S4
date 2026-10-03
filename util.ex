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
    mensaje
    |> IO.gets()
    |> String.trim()
  end

 def ingresar(mensaje, :booleano) do
     valor = mensaje
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
    :io_lib.format("~.2f", [valor]) |> List.to_string()
  end


  @doc """
  Funcion generada con IA para pasar de una cadena de texto a un valor numerico que puede ser entero o float
  ## Parametros
   -valor, para convertirlo a dos decimales
  """
  def texto_a_numero(cadena) do
    cadena
    |> String.trim()
    |> Float.parse()
    |> case do
      {numero, _resto} -> numero
      :error -> cadena                  #esto es en caso de que depronto me ingresen un entero individual
                |> String.trim()
                |> Integer.parse()
                |> case do
                  {numero, _resto} -> numero
                  :error -> {:error, "se espera que ingrese un valor valido"}
                end
    end
  end


end
