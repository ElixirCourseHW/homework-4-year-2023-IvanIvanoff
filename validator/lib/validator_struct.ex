defmodule Validator.Struct do
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :validators, accumulate: true)
      @before_compile Validator.Struct
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def valid?(struct) do
        Validator.valid?(struct, @validators)
      end

      def validate(struct) do
        Validator.validate(struct, @validators)
      end
    end
  end

  defmacro validation(field, operation) do
    quote do
      @validators {unquote(field), unquote(operation)}
    end
  end
end

defmodule Validator do
  def validate(struct, validators) do
    validators
    |> group_validators()
    |> Enum.flat_map(fn {field, operations} ->
      run_operations(struct, field, operations)
    end)
    |> Enum.reject(&(&1 == :ok))
    |> case do
      [] ->
        :ok

      errors_list ->
        {:error, errors_list}
    end
  end

  defp run_operations(struct, field, operations) do
    value = Map.get(struct, field)

    case operations[:type] do
      nil ->
        Enum.map(operations[:rest], &apply_rule(&1, struct, field, value))

      operation ->
        case apply_rule(operation, struct, field, value) do
          :ok -> Enum.map(operations[:rest], &apply_rule(&1, struct, field, value))
          {:error, error} -> [{:error, error}]
        end
    end
    |> errors_to_field_kv(field)
  end

  defp errors_to_field_kv(list, field) do
    list
    |> Enum.reject(&(&1 == :ok))
    |> Enum.map(fn {:error, error} -> {field, error} end)
  end

  defp group_validators(validators) do
    validators
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.map(fn {field, operations} ->
      type_operation =
        Enum.find(operations, fn
          [{:type, _type}] -> true
          _ -> false
        end)

      rest_operations = operations -- type_operation

      field_operations = %{type: type_operation, rest: rest_operations}

      {field, field_operations}
    end)
  end

  def valid?(struct, validators) do
    case validate(struct, validators) do
      :ok -> true
      {:error, _} -> false
    end
  end

  defp apply_rule(fun, struct, field, value) when is_function(fun, 3) do
    fun.(struct, field, value)
  end

  defp apply_rule([{:type, expected_type}], _struct, field, value) do
    case get_type(field, value) do
      ^expected_type -> :ok
      value_type -> {:error, "The type must be #{expected_type}, got #{value_type} instead"}
    end
  end

  defp apply_rule([{:length, min..max}], _struct, _field, value) do
    length =
      cond do
        is_binary(value) -> String.length(value)
        is_list(value) -> length(value)
        true -> raise("The length validation accepts only strings and lists.")
      end

    case length do
      len when len in min..max ->
        :ok

      len ->
        {:error,
         "The length must be bettween #{min} and #{max}. Got a value of length #{len} instead."}
    end
  end

  defp apply_rule(:valid_email, _struct, _field, email) when is_binary(email) do
    case Regex.match?(~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/, email) do
      true -> :ok
      false -> {:error, "The value is not a valid email. Got '#{email}' instead."}
    end
  end

  defp apply_rule([{:excludes, forbidden}], _struct, _field, value) do
    case Enum.member?(forbidden, value) do
      false -> :ok
      true -> {:error, "The provided value is not allowed."}
    end
  end

  defp get_type(field, value) do
    cond do
      is_binary(value) -> :binary
      is_atom(value) -> :atom
      is_integer(value) -> :integer
      is_float(value) -> :float
      is_number(value) -> :number
      is_list(value) -> :list
      is_map(value) -> :map
      is_tuple(value) -> :tuple
      true -> raise("Unsupported type used for field #{field}")
    end
  end
end
