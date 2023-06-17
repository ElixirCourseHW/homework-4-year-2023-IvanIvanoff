defmodule ValidatorTest do
  use ExUnit.Case

  defmodule UserTest do
    use Validator.Struct
    defstruct ~w[id name email]a

    @forbidden_names ["admin", "moderator", "root"]

    # type validations
    validation(:id, type: :integer)
    validation(:email, type: :binary)
    validation(:name, type: :binary)

    # the rest of the validations
    validation(:name, excludes: @forbidden_names)
    validation(:name, length: 4..20)
    validation(:email, :valid_email)
    validation(:email, length: 5..50)
    validation(:name, &__MODULE__.does_not_start_with_admin/3)

    def does_not_start_with_admin(_struct, _field, value) do
      case String.starts_with?(value, "admin") do
        false -> :ok
        true -> {:error, "The value can't start with 'admin'"}
      end
    end
  end

  test "validator with all ok fields" do
    u = %UserTest{id: 1, name: "John", email: "john@example.com"}

    assert true == UserTest.valid?(u)
    assert :ok == UserTest.validate(u)
  end

  test "all fields wrong type, don't check the other validations" do
    u = %UserTest{id: "123", name: 5, email: {"john", "@", "com"}}

    assert false == UserTest.valid?(u)

    assert {:error, errors_list} = UserTest.validate(u)

    assert errors_list[:email] =~ "type must be binary"
    assert errors_list[:email] =~ "tuple instead"
    assert errors_list[:id] =~ "type must be integer"
    assert errors_list[:id] =~ "binary instead"
    assert errors_list[:name] =~ "type must be binary"
    assert errors_list[:name] =~ "integer instead"
  end

  test "correct types, failed validations" do
    u = %UserTest{id: 123, name: "Jo", email: "jo"}
    assert false == UserTest.valid?(u)

    assert {:error, errors_list} = UserTest.validate(u)

    assert length(errors_list) == 3

    errors_list[:name] =~ "length must be bettween 4 and 20"
    errors_list[:name] =~ "value of length 2 instead"

    assert multiple_errors_with_patterns(errors_list, :email, [
             ["length must be bettween 5 and 50", "value of length 2 instead"],
             ["value is not a valid email"]
           ])
  end

  test "validate excludes" do
    u = %UserTest{id: 123, name: "admin", email: "joe@example.com"}
    assert false == UserTest.valid?(u)

    assert {:error, errors_list} = UserTest.validate(u)
    assert length(errors_list) == 2

    assert multiple_errors_with_patterns(errors_list, :email, [
             ["value can't start with 'admin'"],
             ["provided value is not allowed"]
           ])
  end

  defp multiple_errors_with_patterns(list, key, patterns) do
    # Given a list of errors where the keys can be duplicated like this:
    # [
    #  email: "The length must be bettween 5 and 50. Got a value of length 2 instead.",
    #  email: "The value is not a valid email. Got 'jo' instead.",
    #  name: "The length must be bettween 4 and 20. Got a value of length 2 instead."
    # ]
    # and a list of patterns like:
    # [
    #   ["length must be bettween 5 and 50", "value of length 2 instead"],
    #   ["value is not a valid email"]
    # ]
    # where each pattern is a list of strings that all must be match in the same error message,
    # check if all the patterns are valid for some of the strings for that field

    values =
      Enum.filter(list, fn {k, _} -> k == key end)
      |> Enum.map(fn {_, v} -> v end)

    Enum.all?(patterns, fn pattern_list ->
      Enum.any?(values, fn value ->
        for p <- pattern_list do
          value =~ p
        end
      end)
    end)
    |> case do
      true ->
        true

      false ->
        {:error, "The list #{inspect(list)} does not match the patterns #{inspect(patterns)}"}
    end
  end
end
