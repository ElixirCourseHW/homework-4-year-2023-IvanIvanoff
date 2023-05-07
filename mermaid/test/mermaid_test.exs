defmodule MermaidTest do
  use ExUnit.Case
  require Mermaid

  doctest Mermaid

  test "one node no edges" do
    md =
      Mermaid.to_md do
        type Flowchart
        direction BT
        A[text: "Node 1", shape: :rectangle]
      end

    assert md ==
             """
             flowchart BT
             A[Node 1]
             """
             # Използването на heredoc добавя по един `\n` в началото и в края.
             # В имплементацията не трябва да има leading и trailing `\n`
             |> String.trim("\n")
  end

  test "two nodes, no link text, nondirectional" do
    md =
      Mermaid.to_md do
        type Flowchart
        direction LR
        A[text: "Node 1"] -- B[text: "Node 2"]
      end

    assert md ==
             """
             flowchart LR
             A[Node 1] --- B[Node 2]
             """
             |> String.trim("\n")
  end

  test "two nodes, no link text, directional" do
    md =
      Mermaid.to_md do
        type Flowchart
        direction LR
        A[text: "Node 1"] ~>> B[text: "Node 2"]
      end

    assert md ==
             """
             flowchart LR
             A[Node 1] --> B[Node 2]
             """
             |> String.trim("\n")
  end

  test "three nodes, one without edges" do
    md =
      Mermaid.to_md do
        type Flowchart
        direction LR
        A[text: "Node 1", shape: :rectangle]
        B[text: "Node 2", shape: :oval] -- C[text: "Node 3"]
      end

    assert md ==
             """
             flowchart LR
             A[Node 1]
             B(Node 2) --- C[Node 3]
             """
             |> String.trim("\n")
  end

  test "two nodes with nondirectional link" do
    md =
      Mermaid.to_md do
        type Flowchart
        direction LR
        A[text: "Node 1", shape: :oval] -- [link_text: "This is a link"] -- B[text: "Node 2"]
      end

    assert md ==
             """
             flowchart LR
             A(Node 1) --- |This is a link| B[Node 2]
             """
             |> String.trim("\n")
  end

  test "title" do
    md =
      Mermaid.to_md do
        type Flowchart
        direction TB
        title "This is a title"

        A[text: "Node 1", shape: :rhombus]
      end

    assert md ==
             """
             ---
             Title: This is a title
             ---
             flowchart TB
             A{Node 1}
             """
             |> String.trim("\n")
  end

  test "multiple nodes and links mixed" do
    md =
      Mermaid.to_md do
        type Flowchart
        direction TB
        title "This is a title"

        A[text: "Node 1"] -- [link_text: "Link 1"] -- B[text: "Node 2"]
        A ~>> [link_text: "Link 2"] ~>> C[text: "Node 3"]
        B ~>> C
        C -- [link_text: "Link 3"] -- D[text: "Node 4"]
        B ~>> [link_text: "Link 4"] ~>> E[text: "Node 5", shape: :rhombus]
        A -- E
      end

    assert md ==
             """
             ---
             Title: This is a title
             ---
             flowchart TB
             A[Node 1] --- |Link 1| B[Node 2]
             A --> |Link 2| C[Node 3]
             B --> C
             C --- |Link 3| D[Node 4]
             B --> |Link 4| E{Node 5}
             A --- E
             """
             |> String.trim("\n")
  end

  test "multiple nodes and links mixed, non-linked nodes existing" do
    md =
      Mermaid.to_md do
        type Flowchart
        direction TD
        title "My FMI Example"

        A[text: "Node 1", shape: :oval] --
          [link_text: "This is a link"] -- B[text: "Node 2", shape: :oval]

        C[text: "Node 3", shape: :oval] ~>> D[text: "Node 4", shape: :oval]

        E[text: "Node with no links"]

        A ~>> [link_text: "This is another link"] ~>> D
      end

    assert md ==
             """
             ---
             Title: My FMI Example
             ---
             flowchart TD
             A(Node 1) --- |This is a link| B(Node 2)
             C(Node 3) --> D(Node 4)
             E[Node with no links]
             A --> |This is another link| D
             """
             |> String.trim("\n")
  end
end
