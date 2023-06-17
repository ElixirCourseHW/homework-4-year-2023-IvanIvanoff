defmodule Mermaid.Diagram do
  defmodule Row do
    defstruct [:left_node, :right_node, :link_text, :line, :edge_type]
  end

  defstruct attrs: %{}, rows: []

  def new(), do: %__MODULE__{}

  def put_attr(diagram, key, text) do
    %{diagram | attrs: Map.put(diagram.attrs, key, text)}
  end

  def add_row(%{rows: rows} = diagram, %Row{} = row) do
    %{diagram | rows: [row | rows]}
  end

  def to_md(%__MODULE__{} = diagram) do
    title_str = if title = diagram.attrs[:title], do: "---\nTitle: #{title}\n---"

    type = diagram.attrs[:type] || raise "type required"
    direction = diagram.attrs[:direction] || raise "direction required"

    type_str =
      "#{Macro.to_string(type) |> String.downcase()} #{Macro.to_string(direction)}"
      |> String.replace(":", "")

    rows = get_sorted_rows(diagram)

    rows_str =
      Enum.map(rows, fn row -> row_to_md(row) end)

    [
      title_str,
      type_str,
      rows_str
    ]
    |> Enum.reject(&is_nil/1)
    |> List.flatten()
    |> Enum.join("\n")
  end

  defp get_sorted_rows(%{rows: rows}) do
    Enum.sort_by(rows, & &1.line)
  end

  defp row_to_md(%Row{left_node: node, right_node: nil}) do
    node_to_str(node)
  end

  defp row_to_md(%Row{link_text: nil, edge_type: :directional} = row) do
    left_node_str = node_to_str(row.left_node)
    right_node_str = node_to_str(row.right_node)

    left_node_str <> " --> " <> right_node_str
  end

  defp row_to_md(%Row{link_text: nil, edge_type: :nondirectional} = row) do
    left_node_str = node_to_str(row.left_node)
    right_node_str = node_to_str(row.right_node)

    left_node_str <> " --- " <> right_node_str
  end

  defp row_to_md(%Row{edge_type: :directional} = row) do
    left_node_str = node_to_str(row.left_node)
    right_node_str = node_to_str(row.right_node)

    left_node_str <> " --> " <> "|#{row.link_text}| " <> right_node_str
  end

  defp row_to_md(%Row{edge_type: :nondirectional} = row) do
    left_node_str = node_to_str(row.left_node)
    right_node_str = node_to_str(row.right_node)

    left_node_str <> " --- " <> "|#{row.link_text}| " <> right_node_str
  end

  defp node_to_str({node_name, nil = _params}),
    do: Macro.to_string(node_name) |> String.trim_leading(":")

  defp node_to_str({node_name, params}) do
    text = Keyword.get(params, :text) || raise("A node must have a :text field defined")
    node_name = Macro.to_string(node_name) |> String.trim_leading(":")

    case Keyword.get(params, :shape, :rectangle) do
      :rectangle ->
        node_name <> "[" <> text <> "]"

      :rhombus ->
        node_name <> "{" <> text <> "}"

      :oval ->
        node_name <> "(" <> text <> ")"

      shape ->
        raise("Unknown shape #{inspect(shape)}. Must be one of: :rectangle, :oval, :rhombus")
    end
  end
end
