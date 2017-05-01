import { expect } from 'chai';
import { mount } from 'enzyme';
import Immutable  from 'immutable';
import { IntlProvider } from 'react-intl';
import { Router, Route, createMemoryHistory } from 'react-router';

import StatusContent from '../../../app/assets/javascripts/components/components/status_content';
import getMessagesForLocale from '../../../app/assets/javascripts/components/locales';

const buildApplication = (options = {}) => {
  return Immutable.fromJS({
    name: options.name || 'Web',
    website: options.website || null,
  });
};

const buildMention = (options = {}) => {
  const account = buildAccount(options);

  return Immutable.fromJS({
    id: account.get('id'),
    acct: account.get('acct'),
    username: account.get('username'),
    url: account.get('url'),
  });
}

const buildAccount = (options = {}) => {
  const username = options.username || 'username';

  return Immutable.fromJS({
    id: options.id || 0,
    username: username,
    display_name: options.display_name || '',
    acct: options.domain ? `${username}@${options.domain}` : username,
    note: options.note || '<p></p>',
    url: options.url || `https://${options.domain || 'mastodon.dev'}/@${username}`,
    avater: options.avater || 'https://mastodon.dev/avater.png',
    avater_static: options.avater_static || 'https://mastodon.dev/avater.png',
    header_static: options.header_static || 'https://mastodon.dev/header.png',
    following_count: options.following_count || 0,
    followers_count: options.followers_count || 0,
    statuses_count: options.statuses_count || 0,
    created_at: options.created_at || new Date().toISOString(),
    locked: options.locked || false,
  });
};

const buildStatus = (options = {}) => {
  const id = options.id || 0;
  const account = buildAccount(options.account || {});

  return Immutable.fromJS({
    id,
    in_reply_to_account_id: options.in_reply_to_account_id || null,
    application: buildApplication(options.application || {}),
    account: account,
    reblog: options.reblog && buildStatus(options.reblog),
    content: options.content || '<p></p>',
    unescaped_content: options.unescaped_content || '',
    spoiler_text: options.spoiler_text || '',
    uri: options.uri || `tag:mastodon.dev,1970-01-01:objectId=${id}:objectType=Status`,
    url: options.url || `https://mastodon.dev/@${account.get('id')}/${id}`,
    favourited: options.favourited || null,
    reblogged: options.reblogged || null,
    reblogs_count: options.reblogs_count || 1,
    favourites_count: options.favourites_count || 0,
    sensitive: options.sensitive || false,
    visibility: options.visibility || 'public',
    tags: options.tags || [],
    mentions: options.mentions || [],
    media_attachments: options.media_attachments || [],
    created_at: options.created_at || new Date().toISOString(),
  });
};

describe('<StatusContent />', () => {
  let history, location;
  beforeEach(() => {
    history = createMemoryHistory();
    history.listen((nextLocation) => { location = nextLocation });
  });

  const buildComponent = (status) => {
    return (
      <IntlProvider locale="en" messages={getMessagesForLocale('en')}>
        <Router history={history}>
          <Route path="*" component={() => <StatusContent status={status} />}/>
        </Router>
      </IntlProvider>
    );
  };

  context('when the given status has a div element', () => {
    it('renders the div element', () => {
      const content = '<p>Toot</p>';
      const status = buildStatus({ content });
      const wrapper = mount(buildComponent(status));

      expect(wrapper.find('div.status__content').html()).to.contain(content);
    });
  });

  context('when the given status has spoiler_text', () => {
    it('renders the content of the status but it is hidden', () => {
      const spoiler_text = 'Caution';
      const content = '<p>Toot</p>';
      const status = buildStatus({ spoiler_text, content });
      const wrapper = mount(buildComponent(status));

      expect(wrapper.find('div.status__content').html()).to.contain(spoiler_text);
      expect(wrapper.find('div.status__content').findWhere(el => el.props().style && el.props().style.display === 'none').html()).to.contain(content);
    });
  });

  context('when the given stautus has a mention', () => {
    context('and we click the mention', () => {
      it('goes to its account page', () => {
        const mention = buildMention();
        const content = `<p><a class="test-mention" href="${mention.get('url')}">@${mention.get('acct')}</a></p>`;
        const status = buildStatus({ content, mentions: [mention] });
        const wrapper = mount(buildComponent(status));

        // Use jsdom's API because enzyme cannot search elements built by using dangerouslySetInnerHTML and cannot invoke callbacks defined by addEventListener.
        wrapper.getDOMNode().querySelector('a.test-mention').dispatchEvent(new window.MouseEvent('click'));
        expect(location.pathname).to.equal(`/accounts/${mention.get('id')}`);
      });
    });
  });

  context('when the given status has a hashtag', () => {
    context('and we click the mention', () => {
      it('goes to its hashtag page', () => {
        const hashtagName = "mastodon"
        const content = `<p><a class="test-hashtag" href="#${hashtagName}">#${hashtagName}</a></p>`;
        const status = buildStatus({ content });
        const wrapper = mount(buildComponent(status));

        wrapper.getDOMNode().querySelector('a.test-hashtag').dispatchEvent(new window.MouseEvent('click'));
        expect(location.pathname).to.equal(`/timelines/tag/${hashtagName}`);
      });
    });
  });
});
