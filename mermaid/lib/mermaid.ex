defmodule Mermaid do
  alias Mermaid.Diagram
  alias Mermaid.Diagram

  defmacro to_md(do: do_clause) do
    diagram = Mermaid.build_diagram(do_clause)

    Diagram.to_md(diagram)
  end

  def build_diagram(ast) do
    case ast do
      {:__block__, _, list} ->
        Enum.reduce(list, Diagram.new(), &build_diagram/2)

      {_, _, _} = tuple ->
        build_diagram(tuple, Diagram.new())

      _ ->
        raise(ArgumentError, message: "Unexpected message format")
    end
  end

  defp build_diagram({:type, _, [{_, _, [type]}]}, diagram) do
    Diagram.put_attr(diagram, :type, type)
  end

  defp build_diagram({:title, _, [title]}, diagram) do
    Diagram.put_attr(diagram, :title, title)
  end

  defp build_diagram({:direction, _, [{_, _, [direction]}]}, diagram) do
    Diagram.put_attr(diagram, :direction, direction)
  end

  defp build_diagram({edge_operator, context, [node1, node2]}, diagram)
       when edge_operator in [:--, :~>>] do
    line = Keyword.fetch!(context, :line)
    edge_type = edge_operator_type(edge_operator)

    row = %Diagram.Row{line: line, edge_type: edge_type}

    cond do
      match?({^edge_operator, _, _}, node1) ->
        {^edge_operator, _, args} = node1
        {link_text, real_node1} = get_link_and_node(edge_operator, args)

        row = %Diagram.Row{
          row
          | left_node: real_node1,
            right_node: to_node(node2),
            link_text: link_text
        }

        Diagram.add_row(diagram, row)

      match?({^edge_operator, _, _}, node2) ->
        {^edge_operator, _, args} = node2
        {link_text, real_node2} = get_link_and_node(edge_operator, args)

        row = %Diagram.Row{
          row
          | left_node: to_node(node1),
            right_node: real_node2,
            link_text: link_text
        }

        Diagram.add_row(diagram, row)

      true ->
        row = %Diagram.Row{row | left_node: to_node(node1), right_node: to_node(node2)}

        Diagram.add_row(diagram, row)
    end
  end

  defp build_diagram({_, context, _} = node_alias, diagram) do
    node =
      to_node(node_alias)

    line = Keyword.fetch!(context, :line)
    row = %Diagram.Row{line: line, left_node: node}

    Diagram.add_row(diagram, row)
  end

  defp get_link_and_node(:--, [link_node, node]), do: {to_link(link_node), to_node(node)}
  defp get_link_and_node(:~>>, [node, link_node]), do: {to_link(link_node), to_node(node)}

  defp edge_operator_type(:--), do: :nondirectional
  defp edge_operator_type(:~>>), do: :directional

  defp to_link(keyword) do
    Keyword.fetch!(keyword, :link_text)
  end

  defp to_node({:__aliases__, _, [node_name]}) do
    {node_name, nil}
  end

  defp to_node({{:., _, [Access, :get]}, _, [{:__aliases__, _, [node_name]}, node_params]}) do
    {node_name, node_params}
  end
end

defmodule MermaidUsage do
  require Mermaid

  def run() do
    md =
      Mermaid.to_md do
        type(Flowchart)
        direction(TD)
        title("My FMI Example")

        A[text: "Node 1", shape: :oval] --
          [link_text: "This is a link"] -- B[text: "Node 2", shape: :oval]

        C[text: "Node 3", shape: :oval] ~>> D[text: "Node 4", shape: :oval]

        F[text: "Node with no links"]

        A ~>> [link_text: "This is another link"] ~>> D
      end

    IO.inspect(md)
  end
end
