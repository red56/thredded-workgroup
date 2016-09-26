# frozen_string_literal: true
module Thredded
  module PersonalizedNavigation
    class NavsController < Thredded::PersonalizedNavigation::ApplicationController
      before_action :thredded_require_login!, except: :root

      def unread
        @topics = gather_topics(Thredded::Topic.unread_followed_by(current_user))
      end

      def following
        @topics = gather_topics(Thredded::Topic.followed_by(current_user))
      end

      def all_topics
        @topics = gather_topics(Thredded::Topic.all)
      end

      def awaiting
        @topics = gather_topics(Thredded::Topic.followed_by(current_user).where(last_user_id: current_user.id))
      end

      protected

      def gather_topics(scope)
        Thredded::TopicsPageView.new(
          thredded_current_user,
          scope
            .order_recently_posted_first
            .includes(:categories, :last_user, :user, :last_post, :messageboard, :followers)
            .page(current_page)
        )
      end

      def current_page
        (params[:page] || 1).to_i
      end
    end
  end
end
