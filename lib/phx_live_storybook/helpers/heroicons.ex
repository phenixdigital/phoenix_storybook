defmodule PhxLiveStorybook.Heroicons do
  import Phoenix.HTML

  @default_class "lsb-h-4 lsb-w-4"

  def heroicon(_icon, class \\ @default_class)

  def heroicon(:chevron_down, class) do
    raw("""
    <svg xmlns="http://www.w3.org/2000/svg" class="#{class}" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
    </svg>
    """)
  end

  def heroicon(:chevron_right, class) do
    raw("""
    <svg xmlns="http://www.w3.org/2000/svg" class="#{class}" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
    </svg>
    """)
  end

  def heroicon(:book, class) do
    raw("""
    <svg xmlns="http://www.w3.org/2000/svg" class="#{class}" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
    </svg>
    """)
  end
end
