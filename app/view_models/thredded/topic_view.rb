# frozen_string_literal: true

require_dependency File.expand_path("../../app/view_models/thredded/topic_view", Thredded::Engine.called_from)
module Thredded
  class TopicView < Thredded::BaseTopicView
    def path
      anchor = if @read_state.first_unread_post_page
                 "unread"
               elsif @topic.last_post
                 "post_#{@topic.last_post.id}"
               end
      page = @read_state.first_unread_post_page || @read_state.last_read_post_page
      Thredded::UrlsHelper.topic_path(@topic, page: page, anchor: anchor)
    end
  end
end
