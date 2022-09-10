defmodule PhxLiveStorybook.TemplateHelpersTest do
  use ExUnit.Case, async: true

  import PhxLiveStorybook.TemplateHelpers

  test "set_template_id/2" do
    template =
      set_template_id(
        """
        <div id=":story_id">
          <.story/>
        </div>
        """,
        :hello_world
      )

    assert template == """
           <div id="hello_world">
             <.story/>
           </div>
           """
  end

  test "story_template?/1" do
    assert story_template?("<div><.story/></div>")
    assert story_template?("<div><.story  /></div>")
    assert story_template?("<div><.story whatever /></div>")

    assert story_template?("""
           <div>
             <.story/>
           </div>
           """)

    refute story_template?("<div><story/></div>")
    refute story_template?("<div><.story-group/></div>")
  end

  test "story_group_template?/1" do
    assert story_group_template?("<div><.story-group/></div>")
    assert story_group_template?("<div><.story-group  /></div>")
    assert story_group_template?("<div><.story-group whatever /></div>")

    assert story_group_template?("""
           <div>
             <.story-group/>
           </div>
           """)

    refute story_group_template?("<div><story-group/></div>")
    refute story_group_template?("<div><.story/></div>")
  end

  test "replace_template_story/2" do
    heex =
      replace_template_story(
        """
        <div>
          <.story/>
        </div>
        """,
        "<span/>"
      )

    assert heex == """
           <div>
             <span/>
           </div>
           """
  end

  test "replace_template_story/2 with indentation" do
    heex =
      replace_template_story(
        """
        <div>
          <div>
            <.story/>
          </div>
        </div>
        """,
        """
        <span>
          <span>
            hello
          </span>
        </span>
        """,
        _indent = true
      )

    assert heex == """
           <div>
             <div>
               <span>
                 <span>
                   hello
                 </span>
               </span>
             </div>
           </div>
           """
  end

  test "replace_template_story_group/2" do
    heex =
      replace_template_story_group(
        """
        <div>
          <.story-group/>
        </div>
        """,
        "<span/>"
      )

    assert heex == """
           <div>
             <span/>
           </div>
           """
  end
end
