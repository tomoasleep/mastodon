# frozen_string_literal: true

require 'singleton'
require_relative './sanitize_config'

class Formatter
  include Singleton
  include RoutingHelper

  include ActionView::Helpers::TextHelper

  def format(status)
    return reformat(status.content) unless status.local?
    return process_markdown(status.text).html_safe if markdown_mode?(status.text)

    html = status.text
    html = encode_and_link_urls(html)
    html, marks = swap_code_literal_to_marker(html)
    html = simple_format(html, {}, sanitize: false)
    html = html.delete("\n")
    html = link_mentions(html, status.mentions)
    html = link_hashtags(html)
    html = swap_marker_to_code_blocks(html, marks)

    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def reformat(html)
    sanitize(html, Sanitize::Config::MASTODON_STRICT).html_safe # rubocop:disable Rails/OutputSafety
  end

  def plaintext(status)
    return status.text if status.local?
    strip_tags(status.text)
  end

  def simplified_format(account)
    return reformat(account.note) unless account.local?

    html = encode_and_link_urls(account.note)
    html = simple_format(html, {}, sanitize: false)
    html = html.delete("\n")
    html = link_accounts(html)
    html = link_hashtags(html)

    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def sanitize(html, config)
    Sanitize.fragment(html, config)
  end

  private

  def encode(html)
    HTMLEntities.new.encode(html)
  end

  def encode_and_link_urls(html)
    entities = Twitter::Extractor.extract_urls_with_indices(html, extract_url_without_protocol: false)
    entities = entities.sort_by { |entity| entity[:indices].first }

    chars = html.to_s.to_char_a
    html_attrs = {
      target: '_blank',
      rel: 'nofollow noopener',
    }
    result = ''

    last_index = entities.reduce(0) do |index, entity|
      normalized_url = Addressable::URI.parse(entity[:url]).normalize
      indices = entity[:indices]
      result += encode(chars[index...indices.first].join)
      result += Twitter::Autolink.send(:link_to_text, entity, link_html(entity[:url]), normalized_url, html_attrs)
      indices.last
    end
    result += encode(chars[last_index..-1].join)
  end

  def link_mentions(html, mentions)
    html.gsub(Account::MENTION_RE) do |match|
      acct    = Account::MENTION_RE.match(match)[1]
      mention = mentions.find { |item| TagManager.instance.same_acct?(item.account.acct, acct) }

      mention.nil? ? match : mention_html(match, mention.account)
    end
  end

  def link_accounts(html)
    html.gsub(Account::MENTION_RE) do |match|
      acct = Account::MENTION_RE.match(match)[1]
      username, domain = acct.split('@')
      domain = nil if TagManager.instance.local_domain?(domain)
      account = Account.find_remote(username, domain)

      account.nil? ? match : mention_html(match, account)
    end
  end

  def link_hashtags(html)
    html.gsub(Tag::HASHTAG_RE) do |match|
      hashtag_html(match)
    end
  end

  def link_html(url)
    url = Addressable::URI.parse(url).display_uri.to_s
    prefix = url.match(/\Ahttps?:\/\/(www\.)?/).to_s
    text   = url[prefix.length, 30]
    suffix = url[prefix.length + 30..-1]
    cutoff = url[prefix.length..-1].length > 30

    "<span class=\"invisible\">#{prefix}</span><span class=\"#{cutoff ? 'ellipsis' : ''}\">#{text}</span><span class=\"invisible\">#{suffix}</span>"
  end

  def hashtag_html(match)
    prefix, _, affix = match.rpartition('#')
    "#{prefix}<a href=\"#{tag_url(affix.downcase)}\" class=\"mention hashtag\">#<span>#{affix}</span></a>"
  end

  def mention_html(match, account)
    "#{match.split('@').first}<span class=\"h-card\"><a href=\"#{TagManager.instance.url_for(account)}\" class=\"u-url mention\">@<span>#{account.username}</span></a></span>"
  end

  def swap_code_literal_to_marker(html)
    marks = []
    index = html.scan(/\[\[\[codeblock(\d+)\]\]\]/).map(&:to_i).max || 0

    html = html.gsub(/^```(?<lang>[^\n]*)\n(?<code>.*)\n```$/m) do |match|
      lang = $1
      code = $2
      marker = "[[[codeblock#{index += 1}]]]"
      block_html = "<pre><code #{ lang ? "data-language=\"#{ sanitize(lang, Sanitize::Config::MASTODON_STRICT).gsub(/["']/, '') }\"" : "" }>#{ sanitize(code, Sanitize::Config::MASTODON_STRICT) }</code></pre>"
      marks << [marker, block_html]
      marker
    end

    html = html.gsub(/`(?<code>[^`\n]+)`/) do |match|
      code = $1
      marker = "[[[codeblock#{index += 1}]]]"
      block_html = "<code class=\"singleline\">#{ sanitize(code, Sanitize::Config::MASTODON_STRICT) }</code>"
      marks << [marker, block_html]
      marker
    end

    [html, marks]
  end

  def swap_marker_to_code_blocks(html, marks)
    marks.reverse.reduce(html) do |html, (marker, block_html)|
      html.gsub(marker, block_html)
    end
  end

  def markdown_mode?(html)
    !!html.match(/^!markdown\n/)
  end

  def process_markdown(html)
    Qiita::Markdown::Processor.new(hostname: Rails.configuration.x.web_domain).call(html.sub(/^!markdown\n/, ''))[:output].to_s
  end
end
