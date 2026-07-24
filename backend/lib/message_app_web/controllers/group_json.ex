defmodule MessageAppWeb.GroupJSON do
  def render("index.json", %{groups: groups}) do
    %{
      data: Enum.map(groups.entries, &group_json/1),
      pagination: %{
        page: groups.page,
        per_page: groups.per_page,
        total: groups.total,
        total_pages: groups.total_pages
      }
    }
  end

  def render("show.json", %{group: group}) do
    %{data: group_json(group)}
  end

  defp group_json(group) do
    created_by = Map.get(group, :created_by)
    members = Map.get(group, :members) || []

    %{
      id: group.id,
      name: group.name,
      description: group.description,
      avatar_url: group.avatar_url,
      created_by: if(created_by, do: %{id: created_by.id, name: created_by.name, nickname: created_by.nickname}, else: nil),
      members_count: length(members),
      inserted_at: group.inserted_at,
      updated_at: group.updated_at
    }
  end
end
