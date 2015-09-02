###* @jsx React.DOM ###

window.BigQueryLogViewer ||= {}

BigQueryLogViewer.Pagination = React.createClass
  render: ->
    removeNode =
      if @props.type == 'top'
        <span className={'remove-wrapper'} onClick={@props.handleTabDelete}>
          <i className={'icon icon-remove'}></i>
        </span>

    tabs =
      for tab in @props.tabs
        <li key={tab.key} className={'active' if tab.active}>
          <a href={'#'}>
            <span onClick={tab.handler || @props.handleTabSwitch} dangerouslySetInnerHTML={__html: tab.title} />
            {removeNode}
          </a>
        </li>

    if @props.type == 'top'
      return (
        <ul className={'nav nav-tabs'}>
          {tabs}
        </ul>
      )
    else
      return (
        <div className={'pagination'}>
          <ul>
            {tabs}
          </ul>
        </div>
      )