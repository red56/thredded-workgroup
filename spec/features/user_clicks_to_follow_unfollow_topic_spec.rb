# frozen_string_literal: true
require "spec_helper"

describe "Clicking to follow / unfollow topics", type: :feature do
  let(:messageboard) { create(:messageboard, name: "Some message board") }
  let(:user) { create(:user) }
  let(:log_in) do
    visit main_app.new_user_session_path
    fill_in "name", with: user.name
    click_button "Sign in"
  end
  before { log_in }

  shared_examples_for "follow and unfollow from list" do
    context "with an unfollowed topic" do
      let(:topic) { create(:topic, messageboard: messageboard) }
      let(:post) { create(:post, postable: topic) }

      specify "you can click to follow", js: true do
        puts "about to create post"
        post
        puts "created post"
        visit path
        within "#topic_#{topic.id}.thredded--topic-notfollowing" do
          find("svg.thredded--topics--follow-icon").click
        end
        TransactionalCapybara::AjaxHelpers.wait_for_ajax(page)
        expect(page).to have_css("#topic_#{topic.id}.thredded--topic-following")
        expect(topic.reload.followers).to include(user)
      end
    end

    context "with a followed topic" do
      let!(:post) { create(:post, postable: topic) }
      let!(:topic) do
        create(:topic, messageboard: messageboard).tap do |topic|
          topic.followers << user
        end
      end

      specify "you can click to unfollow", js: true do
        visit path
        within "#topic_#{topic.id}.thredded--topic-following" do
          find("svg.thredded--topics--follow-icon").click
        end
        TransactionalCapybara::AjaxHelpers.wait_for_ajax(page)
        expect(page).to have_css("#topic_#{topic.id}.thredded--topic-notfollowing")
        expect(topic.reload.followers).to_not include(user)
      end
    end
  end

  describe "all_topics_nav_path" do
    let(:path) { all_topics_nav_path }
    it_behaves_like "follow and unfollow from list"
  end

  describe "messageboards_nav_path" do
    let(:path) { thredded_messageboard_path(messageboard) }
    it_behaves_like "follow and unfollow from list"
  end
end
