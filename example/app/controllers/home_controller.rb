class HomeController < ApplicationController

  def index
    # Don't ever write code like this. We're professionals.
    graphql = <<-graphql.sub("      ", "").gsub /\n      /, "\n"
      query {
        my {
          user {
            email
            to_dos(status: "complete") {
              content
              status
            }
          }
        }
      }
    graphql
    render html: <<-html.html_safe
      <html>
        <form action='/query' method='post'>
          <label name='current_user_id'>Current User ID</label>
          <br/>
          <input name='current_user_id' value="1" style="width:100%"></input>
          <br/>
          <label for='query'/>Query</label>
          <br/>
          <textarea name='query' style="width: 100%; height: 300px">#{graphql}</textarea>
          <br/>
          <input type="submit"></input>
        </form>
      </html>
    html
  end

end