import PureRenderMixin from 'react-addons-pure-render-mixin';
import ImmutablePropTypes from 'react-immutable-proptypes';

export default class ConnectAccount extends React.Component {
  constructor(props) {
    super(props);
    this.shouldComponentUpdate = PureRenderMixin.shouldComponentUpdate.bind(this);
  }

  render({ account }) {

    if (!account) {
      return <div />;
    } else {
      return (
        <div className="nico-connect-account">
          { this.renderAccountStatus({ account }) }
        </div>
      );
    }
  }

  renderAccountStatus({ account }) {
    const url_name = account.get('qiita_url_name');

    if (url_name) {
      return (
        <a
          href={`http://qiita.com/${url_name}`}
          target="_blank"
          rel="noopener"
        >
          <span className="qiita-connect-account__label">
            already connected to a Qiita account
          </span>
        </a>
      );
    } else {
      return (
        <a
          className="qiita-connect-account__wrapper"
          href="/auth/auth/qiita"
          >
          <span className="qiita-connect-account__label qiita-connect-account__label--disabled">
            connect to a Qiita account
          </span>
        </a>
      );
    }
  }
}

ConnectAccount.propTypes = {
  account: ImmutablePropTypes.map.isRequired
};
