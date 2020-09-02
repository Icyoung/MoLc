# MoLc

⛩一款基于Provider封装的UI组件

## ModelWidget
只依赖单个Model的小组件，随Model状态变化而刷新状态，适合没有逻辑的页面

## LogicWidget
只依赖单个Logic的小组件，适合没有状态变化但需要初始化的组件

## MoLcWidget
以上两种的组合的小组件，依赖一个Model和一个Logic，即拆分一个页面的逻辑和状态

依靠这三种组合，可以组合出依赖多个Model多个Logic的满足需求的页面。



