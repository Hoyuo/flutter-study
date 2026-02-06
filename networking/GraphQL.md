# Flutter GraphQL 가이드

> GraphQL을 활용한 효율적인 데이터 페칭과 실시간 통신 구현 가이드. Clean Architecture, Bloc 패턴, 타입 안전성을 갖춘 현대적인 Flutter GraphQL 애플리케이션 개발 방법을 다룹니다.

## 1. 개요

### 1.1 GraphQL이란?

GraphQL은 API를 위한 쿼리 언어이자 런타임입니다. 클라이언트가 필요한 데이터의 정확한 구조를 요청할 수 있어 over-fetching과 under-fetching 문제를 해결합니다.

**핵심 특징:**
- **선언적 데이터 페칭**: 클라이언트가 필요한 데이터를 정확히 명시
- **단일 엔드포인트**: 하나의 URL로 모든 데이터 요청 처리
- **강력한 타입 시스템**: Schema로 API 계약 정의
- **실시간 지원**: Subscription을 통한 실시간 데이터 스트림

### 1.2 REST vs GraphQL 비교

| 특성 | REST | GraphQL |
|------|------|---------|
| 엔드포인트 | 리소스별 다수 엔드포인트 | 단일 엔드포인트 |
| 데이터 페칭 | 고정된 응답 구조 | 클라이언트가 필요한 필드만 요청 |
| Over-fetching | 불필요한 데이터 포함 가능 | 정확히 요청한 데이터만 반환 |
| Under-fetching | 여러 요청 필요할 수 있음 | 단일 쿼리로 중첩 데이터 페칭 |
| 버전 관리 | URL 버저닝 필요 | Schema 진화로 자연스러운 변경 |
| 실시간 | SSE, WebSocket 별도 구현 | Subscription 내장 |
| 캐싱 | HTTP 캐싱 활용 용이 | Normalized Cache 필요 |
| 학습 곡선 | 낮음 | 중간~높음 |

### 1.3 사용 시나리오

**GraphQL 추천:**
- 복잡한 중첩 데이터 구조
- 모바일 앱 (대역폭 최적화)
- 실시간 기능 필요
- 다양한 클라이언트 (Web, Mobile, Desktop)
- 빠른 프론트엔드 개발

**REST 추천:**
- 단순한 CRUD 작업
- 파일 업로드/다운로드 중심
- HTTP 캐싱 중요
- 기존 REST 인프라 활용

## 2. 프로젝트 설정

### 2.1 의존성 추가

```yaml
# pubspec.yaml
name: graphql_app
description: GraphQL Flutter application
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^9.1.1
  bloc: ^8.1.4

  # GraphQL
  graphql_flutter: ^5.2.0
  ferry: ^0.16.0
  ferry_flutter: ^0.9.0
  gql: ^1.0.0
  gql_http_link: ^1.0.2
  gql_websocket_link: ^1.0.0

  # Dependency Injection
  injectable: ^2.7.1
  get_it: ^9.2.0

  # Functional Programming
  fpdart: ^1.2.0

  # Code Generation
  freezed_annotation: ^3.1.0
  json_annotation: ^4.9.0
  built_value: ^8.9.2

  # Utils
  equatable: ^2.0.5
  dio: ^5.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.4.13
  freezed: ^3.2.4
  json_serializable: ^6.8.0
  injectable_generator: ^2.6.2
  ferry_generator: ^0.10.0
  gql_code_builder: ^0.8.0

  # Testing
  mockito: ^5.4.4
  bloc_test: ^9.1.7

  # Linting
  flutter_lints: ^5.0.0
```

### 2.2 프로젝트 구조

```
lib/
├── core/
│   ├── di/
│   │   ├── injection.dart
│   │   └── injection.config.dart
│   ├── error/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   └── network/
│       ├── graphql_client.dart
│       └── graphql_config.dart
├── features/
│   └── posts/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── post_remote_datasource.dart
│       │   ├── models/
│       │   │   └── post_model.dart
│       │   └── repositories/
│       │       └── post_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── post.dart
│       │   ├── repositories/
│       │   │   └── post_repository.dart
│       │   └── usecases/
│       │       ├── get_posts.dart
│       │       ├── create_post.dart
│       │       └── subscribe_to_posts.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── post_bloc.dart
│           │   ├── post_event.dart
│           │   └── post_state.dart
│           └── pages/
│               └── posts_page.dart
├── graphql/
│   ├── queries/
│   │   └── posts.graphql
│   ├── mutations/
│   │   └── create_post.graphql
│   └── subscriptions/
│       └── post_updates.graphql
└── main.dart
```

### 2.3 GraphQL 클라이언트 설정

```dart
// lib/core/network/graphql_client.dart
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';

@module
abstract class GraphQLModule {
  @lazySingleton
  GraphQLClient graphQLClient(GraphQLConfig config) {
    final httpLink = HttpLink(config.endpoint);

    final authLink = AuthLink(
      getToken: () async => 'Bearer ${config.token}',
    );

    final wsLink = WebSocketLink(
      config.wsEndpoint,
      config: SocketClientConfig(
        autoReconnect: true,
        inactivityTimeout: const Duration(seconds: 30),
        initialPayload: () async => {
          'Authorization': 'Bearer ${config.token}',
        },
      ),
    );

    final link = Link.split(
      (request) => request.isSubscription,
      wsLink,
      authLink.concat(httpLink),
    );

    return GraphQLClient(
      link: link,
      cache: GraphQLCache(
        store: InMemoryStore(),
      ),
      defaultPolicies: DefaultPolicies(
        query: Policies(
          fetch: FetchPolicy.cacheAndNetwork,
          error: ErrorPolicy.all,
          cacheReread: CacheRereadPolicy.mergeOptimistic,
        ),
        mutate: Policies(
          fetch: FetchPolicy.networkOnly,
          error: ErrorPolicy.all,
        ),
        subscribe: Policies(
          fetch: FetchPolicy.networkOnly,
          error: ErrorPolicy.all,
        ),
      ),
    );
  }
}

@injectable
class GraphQLConfig {
  final String endpoint;
  final String wsEndpoint;
  final String? token;

  GraphQLConfig({
    @Named('graphql_endpoint') required this.endpoint,
    @Named('graphql_ws_endpoint') required this.wsEndpoint,
    this.token,
  });
}
```

## 3. GraphQL 기본

### 3.1 Schema 정의

GraphQL Schema는 API의 타입 시스템을 정의합니다.

```graphql
# schema.graphql

# Object Types
type Post {
  id: ID!
  title: String!
  content: String!
  author: User!
  comments: [Comment!]!
  createdAt: DateTime!
  updatedAt: DateTime!
}

type User {
  id: ID!
  name: String!
  email: String!
  posts: [Post!]!
}

type Comment {
  id: ID!
  text: String!
  author: User!
  post: Post!
  createdAt: DateTime!
}

# Input Types
input CreatePostInput {
  title: String!
  content: String!
  authorId: ID!
}

input UpdatePostInput {
  id: ID!
  title: String
  content: String
}

# Query Type
type Query {
  posts(limit: Int, offset: Int): [Post!]!
  post(id: ID!): Post
  user(id: ID!): User
  searchPosts(query: String!): [Post!]!
}

# Mutation Type
type Mutation {
  createPost(input: CreatePostInput!): Post!
  updatePost(input: UpdatePostInput!): Post!
  deletePost(id: ID!): Boolean!
}

# Subscription Type
type Subscription {
  postCreated: Post!
  postUpdated(id: ID!): Post!
}

# Custom Scalar
scalar DateTime
```

### 3.2 Query, Mutation, Subscription

**Query**: 데이터 읽기 (GET)
**Mutation**: 데이터 변경 (POST, PUT, DELETE)
**Subscription**: 실시간 데이터 스트림

```graphql
# Query 예제
query GetPosts($limit: Int, $offset: Int) {
  posts(limit: $limit, offset: $offset) {
    id
    title
    author {
      id
      name
    }
  }
}

# Mutation 예제
mutation CreatePost($input: CreatePostInput!) {
  createPost(input: $input) {
    id
    title
    content
    createdAt
  }
}

# Subscription 예제
subscription OnPostCreated {
  postCreated {
    id
    title
    author {
      name
    }
  }
}
```

## 4. graphql_flutter 사용법

### 4.1 GraphQLProvider 설정

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHiveForFlutter(); // GraphQL 캐시용
  configureDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: ValueNotifier(getIt<GraphQLClient>()),
      child: MaterialApp(
        title: 'GraphQL Flutter',
        home: const PostsPage(),
      ),
    );
  }
}
```

### 4.2 Query 위젯

```dart
// lib/features/posts/presentation/pages/posts_page.dart
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

const String getPostsQuery = r'''
  query GetPosts($limit: Int) {
    posts(limit: $limit) {
      id
      title
      content
      author {
        id
        name
      }
      createdAt
    }
  }
''';

class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posts')),
      body: Query(
        options: QueryOptions(
          document: gql(getPostsQuery),
          variables: const {'limit': 10},
          pollInterval: const Duration(seconds: 10), // 폴링
          fetchPolicy: FetchPolicy.cacheAndNetwork,
        ),
        builder: (result, {fetchMore, refetch}) {
          if (result.hasException) {
            return Center(
              child: Text('Error: ${result.exception.toString()}'),
            );
          }

          if (result.isLoading && result.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = result.data?['posts'] as List<dynamic>?;

          if (posts == null || posts.isEmpty) {
            return const Center(child: Text('No posts found'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await refetch?.call();
            },
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return ListTile(
                  title: Text(post['title'] as String),
                  subtitle: Text(post['author']['name'] as String),
                  trailing: Text(
                    _formatDate(post['createdAt'] as String),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.year}-${date.month}-${date.day}';
  }
}
```

### 4.3 Mutation 위젯

```dart
// lib/features/posts/presentation/widgets/create_post_form.dart
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

const String createPostMutation = r'''
  mutation CreatePost($input: CreatePostInput!) {
    createPost(input: $input) {
      id
      title
      content
      author {
        id
        name
      }
      createdAt
    }
  }
''';

class CreatePostForm extends StatefulWidget {
  const CreatePostForm({super.key});

  @override
  State<CreatePostForm> createState() => _CreatePostFormState();
}

class _CreatePostFormState extends State<CreatePostForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        document: gql(createPostMutation),
        onCompleted: (dynamic resultData) {
          if (resultData != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Post created successfully!')),
            );
            _formKey.currentState?.reset();
            _titleController.clear();
            _contentController.clear();
          }
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${error?.toString()}')),
          );
        },
        update: (cache, result) {
          // 캐시 업데이트 로직
          if (result?.data != null) {
            final newPost = result!.data!['createPost'];

            // Query 캐시 읽기
            final postsQuery = gql(getPostsQuery);
            final data = cache.readQuery(
              Request(
                operation: Operation(document: postsQuery),
              ),
            );

            if (data != null) {
              final posts = List<dynamic>.from(data['posts'] as List);
              posts.insert(0, newPost);

              // 업데이트된 데이터 쓰기
              cache.writeQuery(
                Request(
                  operation: Operation(document: postsQuery),
                ),
                data: {'posts': posts},
              );
            }
          }
        },
      ),
      builder: (runMutation, result) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: result?.isLoading == true
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          runMutation({
                            'input': {
                              'title': _titleController.text,
                              'content': _contentController.text,
                              'authorId': 'current-user-id',
                            },
                          });
                        }
                      },
                child: result?.isLoading == true
                    ? const CircularProgressIndicator()
                    : const Text('Create Post'),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

## 5. Ferry 클라이언트 (타입 안전)

Ferry는 타입 안전한 GraphQL 클라이언트로 Code Generation을 통해 완전한 타입 안전성을 제공합니다.

### 5.1 Ferry 설정

```yaml
# build.yaml
targets:
  $default:
    builders:
      ferry_generator:
        enabled: true
        options:
          schema: graphql/schema.graphql
```

```dart
// lib/core/network/ferry_client.dart
import 'package:ferry/ferry.dart';
import 'package:gql_http_link/gql_http_link.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
Client ferryClient(GraphQLConfig config) {
  final link = HttpLink(config.endpoint);

  return Client(
    link: link,
    cache: Cache(),
  );
}
```

### 5.2 GraphQL 쿼리 정의

```graphql
# graphql/queries/posts.graphql
query GetPosts($limit: Int, $offset: Int) {
  posts(limit: $limit, offset: $offset) {
    id
    title
    content
    author {
      id
      name
      email
    }
    createdAt
  }
}

query GetPost($id: ID!) {
  post(id: $id) {
    id
    title
    content
    author {
      id
      name
    }
    comments {
      id
      text
      author {
        name
      }
      createdAt
    }
    createdAt
    updatedAt
  }
}
```

### 5.3 Code Generation 실행

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5.4 생성된 코드 사용

```dart
// lib/features/posts/data/datasources/post_remote_datasource.dart
import 'package:ferry/ferry.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../graphql/posts.req.gql.dart';
import '../../../../graphql/posts.data.gql.dart';

abstract class PostRemoteDataSource {
  Future<Either<ServerException, List<GGetPostsData_posts>>> getPosts({
    int? limit,
    int? offset,
  });

  Future<Either<ServerException, GGetPostData_post?>> getPost(String id);
}

@LazySingleton(as: PostRemoteDataSource)
class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final Client _client;

  PostRemoteDataSourceImpl(this._client);

  @override
  Future<Either<ServerException, List<GGetPostsData_posts>>> getPosts({
    int? limit,
    int? offset,
  }) async {
    try {
      final request = GGetPostsReq((b) => b
        ..vars.limit = limit
        ..vars.offset = offset
      );

      final response = await _client.request(request).first;

      if (response.hasErrors) {
        return Left(ServerException(
          message: response.graphqlErrors?.first.message ?? 'Unknown error',
        ));
      }

      if (response.data?.posts == null) {
        return Left(ServerException(message: 'No data received'));
      }

      return Right(response.data!.posts.toList());
    } catch (e) {
      return Left(ServerException(message: e.toString()));
    }
  }

  @override
  Future<Either<ServerException, GGetPostData_post?>> getPost(String id) async {
    try {
      final request = GGetPostReq((b) => b..vars.id = id);

      final response = await _client.request(request).first;

      if (response.hasErrors) {
        return Left(ServerException(
          message: response.graphqlErrors?.first.message ?? 'Unknown error',
        ));
      }

      return Right(response.data?.post);
    } catch (e) {
      return Left(ServerException(message: e.toString()));
    }
  }
}
```

## 6. Query 구현

### 6.1 단순 쿼리

```graphql
# graphql/queries/simple.graphql
query GetUserById($id: ID!) {
  user(id: $id) {
    id
    name
    email
  }
}
```

### 6.2 중첩 쿼리

```graphql
# graphql/queries/nested.graphql
query GetPostWithComments($id: ID!) {
  post(id: $id) {
    id
    title
    content
    author {
      id
      name
      email
      posts {
        id
        title
      }
    }
    comments {
      id
      text
      author {
        id
        name
      }
      createdAt
    }
  }
}
```

### 6.3 Fragment 사용

```graphql
# graphql/fragments/user.graphql
fragment UserFields on User {
  id
  name
  email
}

fragment PostFields on Post {
  id
  title
  content
  createdAt
  updatedAt
}

# graphql/queries/with_fragments.graphql
query GetPostsWithFragments($limit: Int) {
  posts(limit: $limit) {
    ...PostFields
    author {
      ...UserFields
    }
  }
}
```

### 6.4 Pagination 구현

```dart
// lib/features/posts/presentation/widgets/posts_list.dart
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

const String getPostsWithPaginationQuery = r'''
  query GetPostsWithPagination($limit: Int!, $offset: Int!) {
    posts(limit: $limit, offset: $offset) {
      id
      title
      author {
        name
      }
    }
  }
''';

class PostsList extends StatefulWidget {
  const PostsList({super.key});

  @override
  State<PostsList> createState() => _PostsListState();
}

class _PostsListState extends State<PostsList> {
  final int _pageSize = 10;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(getPostsWithPaginationQuery),
        variables: {
          'limit': _pageSize,
          'offset': _currentPage * _pageSize,
        },
        fetchPolicy: FetchPolicy.cacheAndNetwork,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.hasException) {
          return Center(child: Text('Error: ${result.exception}'));
        }

        if (result.isLoading && result.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = result.data?['posts'] as List<dynamic>?;

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: posts?.length ?? 0,
                itemBuilder: (context, index) {
                  final post = posts![index];
                  return ListTile(
                    title: Text(post['title'] as String),
                    subtitle: Text(post['author']['name'] as String),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _currentPage > 0
                      ? () {
                          setState(() => _currentPage--);
                          refetch?.call();
                        }
                      : null,
                ),
                Text('Page ${_currentPage + 1}'),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: posts != null && posts.length == _pageSize
                      ? () {
                          setState(() => _currentPage++);
                          refetch?.call();
                        }
                      : null,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
```

### 6.5 무한 스크롤 (fetchMore)

```dart
// lib/features/posts/presentation/widgets/infinite_posts_list.dart
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class InfinitePostsList extends StatelessWidget {
  const InfinitePostsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(getPostsWithPaginationQuery),
        variables: {'limit': 10, 'offset': 0},
        fetchPolicy: FetchPolicy.cacheAndNetwork,
      ),
      builder: (result, {fetchMore, refetch}) {
        final posts = <dynamic>[];

        if (result.data != null) {
          posts.addAll(result.data!['posts'] as List<dynamic>);
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels ==
                scrollInfo.metrics.maxScrollExtent &&
                !result.isLoading) {
              fetchMore!(
                FetchMoreOptions(
                  variables: {
                    'limit': 10,
                    'offset': posts.length,
                  },
                  updateQuery: (previousResult, fetchMoreResult) {
                    if (fetchMoreResult == null) return previousResult;

                    final prevPosts = previousResult?['posts'] as List? ?? [];
                    final newPosts = fetchMoreResult['posts'] as List;

                    return {
                      'posts': [...prevPosts, ...newPosts],
                    };
                  },
                ),
              );
            }
            return false;
          },
          child: ListView.builder(
            itemCount: posts.length + (result.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == posts.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final post = posts[index];
              return ListTile(
                title: Text(post['title'] as String),
                subtitle: Text(post['author']['name'] as String),
              );
            },
          ),
        );
      },
    );
  }
}
```

## 7. Mutation 구현

### 7.1 데이터 생성

```graphql
# graphql/mutations/create_post.graphql
mutation CreatePost($input: CreatePostInput!) {
  createPost(input: $input) {
    id
    title
    content
    author {
      id
      name
    }
    createdAt
  }
}
```

```dart
// lib/features/posts/domain/usecases/create_post.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';

@injectable
class CreatePost {
  final PostRepository repository;

  CreatePost(this.repository);

  Future<Either<Failure, Post>> call({
    required String title,
    required String content,
    required String authorId,
  }) async {
    return repository.createPost(
      title: title,
      content: content,
      authorId: authorId,
    );
  }
}
```

### 7.2 데이터 수정

```graphql
# graphql/mutations/update_post.graphql
mutation UpdatePost($input: UpdatePostInput!) {
  updatePost(input: $input) {
    id
    title
    content
    updatedAt
  }
}
```

### 7.3 데이터 삭제

```graphql
# graphql/mutations/delete_post.graphql
mutation DeletePost($id: ID!) {
  deletePost(id: $id)
}
```

### 7.4 Optimistic UI

Optimistic UI는 서버 응답을 기다리지 않고 즉시 UI를 업데이트하여 사용자 경험을 개선합니다.

```dart
// lib/features/posts/presentation/widgets/optimistic_mutation.dart
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class OptimisticMutationExample extends StatelessWidget {
  const OptimisticMutationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        document: gql(r'''
          mutation DeletePost($id: ID!) {
            deletePost(id: $id)
          }
        '''),
        optimisticResult: (variables) {
          // Optimistic 응답 정의
          return {
            'deletePost': true,
          };
        },
        update: (cache, result) {
          if (result?.data?['deletePost'] == true) {
            final id = result?.request.variables['id'] as String;

            // 캐시에서 삭제
            final postsQuery = gql(getPostsQuery);
            final data = cache.readQuery(
              Request(operation: Operation(document: postsQuery)),
            );

            if (data != null) {
              final posts = List<dynamic>.from(data['posts'] as List);
              posts.removeWhere((post) => post['id'] == id);

              cache.writeQuery(
                Request(operation: Operation(document: postsQuery)),
                data: {'posts': posts},
              );
            }
          }
        },
      ),
      builder: (runMutation, result) {
        return ElevatedButton(
          onPressed: () {
            runMutation({'id': 'post-id-to-delete'});
          },
          child: const Text('Delete Post'),
        );
      },
    );
  }
}
```

## 8. Subscription (실시간)

### 8.1 Subscription 정의

```graphql
# graphql/subscriptions/post_updates.graphql
subscription OnPostCreated {
  postCreated {
    id
    title
    content
    author {
      id
      name
    }
    createdAt
  }
}

subscription OnPostUpdated($id: ID!) {
  postUpdated(id: $id) {
    id
    title
    content
    updatedAt
  }
}
```

### 8.2 Subscription 위젯

```dart
// lib/features/posts/presentation/widgets/posts_subscription.dart
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

const String postCreatedSubscription = r'''
  subscription OnPostCreated {
    postCreated {
      id
      title
      author {
        name
      }
      createdAt
    }
  }
''';

class PostsSubscription extends StatelessWidget {
  const PostsSubscription({super.key});

  @override
  Widget build(BuildContext context) {
    return Subscription(
      options: SubscriptionOptions(
        document: gql(postCreatedSubscription),
      ),
      builder: (result) {
        if (result.hasException) {
          return Text('Error: ${result.exception}');
        }

        if (result.isLoading) {
          return const Text('Waiting for new posts...');
        }

        if (result.data != null) {
          final post = result.data!['postCreated'];

          // 새 포스트가 도착하면 스낵바 표시
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'New post: ${post['title']} by ${post['author']['name']}',
                ),
              ),
            );
          });
        }

        return const SizedBox.shrink();
      },
    );
  }
}
```

### 8.3 Repository에서 Subscription 사용

```dart
// lib/features/posts/domain/usecases/subscribe_to_posts.dart
import 'package:injectable/injectable.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';

@injectable
class SubscribeToPosts {
  final PostRepository repository;

  SubscribeToPosts(this.repository);

  Stream<Post> call() {
    return repository.subscribeToNewPosts();
  }
}

// lib/features/posts/data/repositories/post_repository_impl.dart
import 'package:ferry/ferry.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../../../../graphql/subscriptions.req.gql.dart';
import '../mappers/post_mapper.dart';

@LazySingleton(as: PostRepository)
class PostRepositoryImpl implements PostRepository {
  final Client _client;
  final PostMapper _mapper;

  PostRepositoryImpl(this._client, this._mapper);

  @override
  Stream<Post> subscribeToNewPosts() {
    final request = GOnPostCreatedReq();

    return _client.request(request).map((response) {
      if (response.data?.postCreated == null) {
        throw Exception('No data received');
      }

      return _mapper.fromGraphQL(response.data!.postCreated);
    });
  }
}
```

## 9. Code Generation

### 9.1 graphql_codegen 설정

```yaml
# build.yaml
targets:
  $default:
    builders:
      gql_code_builder:
        enabled: true
        options:
          schema: graphql/schema.graphql
          type_overrides:
            DateTime: DateTime
```

### 9.2 Freezed 연동

```dart
// lib/features/posts/domain/entities/post.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
class Post with _$Post {
  const factory Post({
    required String id,
    required String title,
    required String content,
    required User author,
    required List<Comment> comments,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class Comment with _$Comment {
  const factory Comment({
    required String id,
    required String text,
    required User author,
    required DateTime createdAt,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);
}
```

### 9.3 Mapper 생성

```dart
// lib/features/posts/data/mappers/post_mapper.dart
import 'package:injectable/injectable.dart';
import '../../domain/entities/post.dart';
import '../../../../graphql/posts.data.gql.dart';

@injectable
class PostMapper {
  Post fromGraphQL(GGetPostsData_posts data) {
    return Post(
      id: data.id,
      title: data.title,
      content: data.content,
      author: User(
        id: data.author.id,
        name: data.author.name,
        email: data.author.email,
      ),
      comments: data.comments.map((c) => Comment(
        id: c.id,
        text: c.text,
        author: User(
          id: c.author.id,
          name: c.author.name,
          email: c.author.email,
        ),
        createdAt: DateTime.parse(c.createdAt as String),
      )).toList(),
      createdAt: DateTime.parse(data.createdAt as String),
      updatedAt: DateTime.parse(data.updatedAt as String),
    );
  }

  GCreatePostInput toGraphQLInput({
    required String title,
    required String content,
    required String authorId,
  }) {
    return GCreatePostInput((b) => b
      ..title = title
      ..content = content
      ..authorId = authorId
    );
  }
}
```

## 10. 캐싱 전략

### 10.1 Normalized Cache

GraphQL의 Normalized Cache는 데이터를 ID 기반으로 정규화하여 중복을 제거하고 일관성을 유지합니다.

```dart
// lib/core/network/cache_config.dart
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';

@module
abstract class CacheModule {
  @lazySingleton
  GraphQLCache graphQLCache() {
    return GraphQLCache(
      store: InMemoryStore(),
      // 커스텀 데이터 ID 추출기
      dataIdFromObject: (object) {
        if (object['__typename'] == 'Post') {
          return 'Post:${object['id']}';
        }
        if (object['__typename'] == 'User') {
          return 'User:${object['id']}';
        }
        return null;
      },
    );
  }
}
```

### 10.2 캐시 정책

| FetchPolicy | 설명 | 사용 시나리오 |
|-------------|------|---------------|
| `cacheFirst` | 캐시 우선, 없으면 네트워크 | 자주 변경되지 않는 데이터 |
| `cacheAndNetwork` | 캐시 먼저 표시 후 네트워크로 갱신 | 최신 데이터 필요하지만 빠른 로딩 원할 때 |
| `networkOnly` | 항상 네트워크 요청 | 항상 최신 데이터 필요 (Mutation) |
| `noCache` | 캐시 사용 안 함 | 일회성 데이터 |
| `cacheOnly` | 캐시만 사용 | 오프라인 모드 |

```dart
// 캐시 정책 예제
QueryOptions(
  document: gql(query),
  fetchPolicy: FetchPolicy.cacheAndNetwork,
  errorPolicy: ErrorPolicy.all, // 에러와 데이터 모두 처리
  cacheRereadPolicy: CacheRereadPolicy.mergeOptimistic, // Optimistic 업데이트 병합
)
```

### 10.3 캐시 수동 업데이트

```dart
// lib/core/network/cache_manager.dart
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';

@injectable
class CacheManager {
  final GraphQLClient _client;

  CacheManager(this._client);

  // 캐시 읽기
  Map<String, dynamic>? readQuery(String query, {Map<String, dynamic>? variables}) {
    try {
      return _client.cache.readQuery(
        Request(
          operation: Operation(
            document: gql(query),
            operationName: null,
          ),
          variables: variables ?? {},
        ),
      );
    } catch (e) {
      return null;
    }
  }

  // 캐시 쓰기
  void writeQuery(
    String query,
    Map<String, dynamic> data, {
    Map<String, dynamic>? variables,
  }) {
    _client.cache.writeQuery(
      Request(
        operation: Operation(
          document: gql(query),
          operationName: null,
        ),
        variables: variables ?? {},
      ),
      data: data,
    );
  }

  // Fragment 읽기
  Map<String, dynamic>? readFragment(
    String fragmentName,
    String fragmentDoc,
    String id,
  ) {
    try {
      return _client.cache.readFragment(
        Fragment(
          document: gql(fragmentDoc),
          fragmentName: fragmentName,
        ),
        idFields: {'__typename': fragmentName, 'id': id},
      );
    } catch (e) {
      return null;
    }
  }

  // Fragment 쓰기
  void writeFragment(
    String fragmentName,
    String fragmentDoc,
    Map<String, dynamic> data,
  ) {
    _client.cache.writeFragment(
      Fragment(
        document: gql(fragmentDoc),
        fragmentName: fragmentName,
      ),
      idFields: {'__typename': fragmentName, 'id': data['id']},
      data: data,
    );
  }

  // 캐시 초기화
  Future<void> reset() async {
    await _client.cache.store.reset();
  }
}
```

## 11. Bloc 연동

### 11.1 PostBloc 구현

```dart
// lib/features/posts/presentation/bloc/post_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_event.freezed.dart';

@freezed
class PostEvent with _$PostEvent {
  const factory PostEvent.loadPosts({int? limit, int? offset}) = LoadPosts;
  const factory PostEvent.loadPost(String id) = LoadPost;
  const factory PostEvent.createPost({
    required String title,
    required String content,
  }) = CreatePost;
  const factory PostEvent.updatePost({
    required String id,
    String? title,
    String? content,
  }) = UpdatePost;
  const factory PostEvent.deletePost(String id) = DeletePost;
  const factory PostEvent.subscribeToNewPosts() = SubscribeToNewPosts;
}

// lib/features/posts/presentation/bloc/post_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/post.dart';

part 'post_state.freezed.dart';

@freezed
class PostState with _$PostState {
  const factory PostState.initial() = _Initial;
  const factory PostState.loading() = _Loading;
  const factory PostState.loaded(List<Post> posts) = _Loaded;
  const factory PostState.error(String message) = _Error;
  const factory PostState.postCreated(Post post) = _PostCreated;
  const factory PostState.postUpdated(Post post) = _PostUpdated;
  const factory PostState.postDeleted(String id) = _PostDeleted;
}

// lib/features/posts/presentation/bloc/post_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/get_posts.dart';
import '../../domain/usecases/create_post.dart';
import '../../domain/usecases/subscribe_to_posts.dart';
import 'post_event.dart';
import 'post_state.dart';
import 'dart:async';

@injectable
class PostBloc extends Bloc<PostEvent, PostState> {
  final GetPosts _getPosts;
  final CreatePost _createPost;
  final SubscribeToPosts _subscribeToPosts;

  StreamSubscription? _subscription;

  PostBloc(
    this._getPosts,
    this._createPost,
    this._subscribeToPosts,
  ) : super(const PostState.initial()) {
    on<LoadPosts>(_onLoadPosts);
    on<CreatePost>(_onCreatePost);
    on<SubscribeToNewPosts>(_onSubscribeToNewPosts);
  }

  Future<void> _onLoadPosts(
    LoadPosts event,
    Emitter<PostState> emit,
  ) async {
    emit(const PostState.loading());

    final result = await _getPosts(
      limit: event.limit,
      offset: event.offset,
    );

    result.fold(
      (failure) => emit(PostState.error(failure.message)),
      (posts) => emit(PostState.loaded(posts)),
    );
  }

  Future<void> _onCreatePost(
    CreatePost event,
    Emitter<PostState> emit,
  ) async {
    final result = await _createPost(
      title: event.title,
      content: event.content,
      authorId: 'current-user-id',
    );

    result.fold(
      (failure) => emit(PostState.error(failure.message)),
      (post) => emit(PostState.postCreated(post)),
    );
  }

  Future<void> _onSubscribeToNewPosts(
    SubscribeToNewPosts event,
    Emitter<PostState> emit,
  ) async {
    await _subscription?.cancel();

    _subscription = _subscribeToPosts().listen(
      (post) {
        emit(PostState.postCreated(post));
      },
      onError: (error) {
        emit(PostState.error(error.toString()));
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
```

### 11.2 BlocProvider 설정

```dart
// lib/features/posts/presentation/pages/posts_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../bloc/post_bloc.dart';
import '../widgets/posts_list_view.dart';

class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PostBloc>()
        ..add(const PostEvent.loadPosts())
        ..add(const PostEvent.subscribeToNewPosts()),
      child: const PostsView(),
    );
  }
}

class PostsView extends StatelessWidget {
  const PostsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posts')),
      body: BlocConsumer<PostBloc, PostState>(
        listener: (context, state) {
          state.maybeWhen(
            error: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
            postCreated: (post) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('New post: ${post.title}')),
              );
              // 목록 새로고침
              context.read<PostBloc>().add(const PostEvent.loadPosts());
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: Text('초기 상태')),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (posts) => PostsListView(posts: posts),
            error: (message) => Center(child: Text('Error: $message')),
            postCreated: (post) => const Center(child: CircularProgressIndicator()),
            postUpdated: (post) => const Center(child: CircularProgressIndicator()),
            postDeleted: (id) => const Center(child: CircularProgressIndicator()),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Create post dialog
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## 12. Error Handling

### 12.1 GraphQL 에러 타입

```dart
// lib/core/error/failures.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure.server(String message) = ServerFailure;
  const factory Failure.network(String message) = NetworkFailure;
  const factory Failure.graphql(List<GraphQLError> errors) = GraphQLFailure;
  const factory Failure.cache(String message) = CacheFailure;
  const factory Failure.unknown(String message) = UnknownFailure;
}

@freezed
class GraphQLError with _$GraphQLError {
  const factory GraphQLError({
    required String message,
    String? path,
    Map<String, dynamic>? extensions,
  }) = _GraphQLError;
}
```

### 12.2 Either 패턴 활용

```dart
// lib/features/posts/domain/repositories/post_repository.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/post.dart';

abstract class PostRepository {
  Future<Either<Failure, List<Post>>> getPosts({int? limit, int? offset});
  Future<Either<Failure, Post>> getPost(String id);
  Future<Either<Failure, Post>> createPost({
    required String title,
    required String content,
    required String authorId,
  });
  Future<Either<Failure, Post>> updatePost({
    required String id,
    String? title,
    String? content,
  });
  Future<Either<Failure, bool>> deletePost(String id);
  Stream<Post> subscribeToNewPosts();
}
```

### 12.3 에러 처리 구현

```dart
// lib/features/posts/data/repositories/post_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';

@LazySingleton(as: PostRepository)
class PostRepositoryImpl implements PostRepository {
  final GraphQLClient _client;

  PostRepositoryImpl(this._client);

  @override
  Future<Either<Failure, List<Post>>> getPosts({int? limit, int? offset}) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(getPostsQuery),
          variables: {'limit': limit, 'offset': offset},
        ),
      );

      if (result.hasException) {
        return Left(_handleException(result.exception!));
      }

      if (result.data == null) {
        return const Left(Failure.server('No data received'));
      }

      final posts = (result.data!['posts'] as List)
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(posts);
    } catch (e) {
      return Left(Failure.unknown(e.toString()));
    }
  }

  Failure _handleException(OperationException exception) {
    if (exception.linkException != null) {
      if (exception.linkException is NetworkException) {
        return const Failure.network('Network error');
      }
      if (exception.linkException is ServerException) {
        return Failure.server(
          exception.linkException!.originalException?.toString() ??
              'Server error',
        );
      }
    }

    if (exception.graphqlErrors.isNotEmpty) {
      final errors = exception.graphqlErrors.map((e) => GraphQLError(
        message: e.message,
        path: e.path?.join('.'),
        extensions: e.extensions,
      )).toList();

      return Failure.graphql(errors);
    }

    return Failure.unknown(exception.toString());
  }
}
```

### 12.4 에러 UI 표시

```dart
// lib/core/widgets/error_view.dart
import 'package:flutter/material.dart';
import '../error/failures.dart';

class ErrorView extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;

  const ErrorView({
    required this.failure,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIcon(),
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _getMessage(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    return failure.when(
      server: (_) => Icons.cloud_off,
      network: (_) => Icons.wifi_off,
      graphql: (_) => Icons.error_outline,
      cache: (_) => Icons.storage,
      unknown: (_) => Icons.warning,
    );
  }

  String _getMessage() {
    return failure.when(
      server: (msg) => '서버 오류: $msg',
      network: (msg) => '네트워크 연결을 확인해주세요',
      graphql: (errors) => errors.first.message,
      cache: (msg) => '캐시 오류: $msg',
      unknown: (msg) => '알 수 없는 오류: $msg',
    );
  }
}
```

## 13. 테스트

### 13.1 Mock GraphQL 서버

```dart
// test/helpers/mock_graphql_client.dart
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([GraphQLClient])
import 'mock_graphql_client.mocks.dart';

class MockGraphQLProvider {
  static MockGraphQLClient createMockClient() {
    return MockGraphQLClient();
  }

  static void mockQuery(
    MockGraphQLClient client,
    String query,
    Map<String, dynamic> data, {
    Map<String, dynamic>? variables,
  }) {
    when(client.query(any)).thenAnswer((_) async {
      return QueryResult(
        data: data,
        source: QueryResultSource.network,
      );
    });
  }

  static void mockMutation(
    MockGraphQLClient client,
    String mutation,
    Map<String, dynamic> data,
  ) {
    when(client.mutate(any)).thenAnswer((_) async {
      return QueryResult(
        data: data,
        source: QueryResultSource.network,
      );
    });
  }
}
```

### 13.2 Repository 테스트

```dart
// test/features/posts/data/repositories/post_repository_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  late PostRepositoryImpl repository;
  late MockGraphQLClient mockClient;

  setUp(() {
    mockClient = MockGraphQLClient();
    repository = PostRepositoryImpl(mockClient);
  });

  group('getPosts', () {
    test('성공 시 Right(List<Post>) 반환', () async {
      // Arrange
      final mockData = {
        'posts': [
          {
            'id': '1',
            'title': 'Test Post',
            'content': 'Test Content',
            'author': {'id': '1', 'name': 'Author', 'email': 'test@test.com'},
            'comments': [],
            'createdAt': '2026-01-01T00:00:00Z',
            'updatedAt': '2026-01-01T00:00:00Z',
          },
        ],
      };

      when(mockClient.query(any)).thenAnswer((_) async {
        return QueryResult(
          data: mockData,
          source: QueryResultSource.network,
        );
      });

      // Act
      final result = await repository.getPosts();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return Right'),
        (posts) {
          expect(posts.length, 1);
          expect(posts.first.title, 'Test Post');
        },
      );
    });

    test('네트워크 오류 시 Left(NetworkFailure) 반환', () async {
      // Arrange
      when(mockClient.query(any)).thenAnswer((_) async {
        return QueryResult(
          exception: OperationException(
            linkException: NetworkException(),
          ),
          source: QueryResultSource.network,
        );
      });

      // Act
      final result = await repository.getPosts();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
        },
        (posts) => fail('Should return Left'),
      );
    });
  });
}
```

### 13.3 Bloc 테스트

```dart
// test/features/posts/presentation/bloc/post_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  late PostBloc bloc;
  late MockGetPosts mockGetPosts;
  late MockCreatePost mockCreatePost;
  late MockSubscribeToPosts mockSubscribeToPosts;

  setUp(() {
    mockGetPosts = MockGetPosts();
    mockCreatePost = MockCreatePost();
    mockSubscribeToPosts = MockSubscribeToPosts();

    bloc = PostBloc(
      mockGetPosts,
      mockCreatePost,
      mockSubscribeToPosts,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('LoadPosts', () {
    final testPosts = [
      const Post(
        id: '1',
        title: 'Test',
        content: 'Content',
        author: User(id: '1', name: 'Author', email: 'test@test.com'),
        comments: [],
        createdAt: '2026-01-01',
        updatedAt: '2026-01-01',
      ),
    ];

    blocTest<PostBloc, PostState>(
      '성공 시 loading → loaded 상태 전환',
      build: () {
        when(mockGetPosts(limit: anyNamed('limit'), offset: anyNamed('offset')))
            .thenAnswer((_) async => Right(testPosts));
        return bloc;
      },
      act: (bloc) => bloc.add(const PostEvent.loadPosts()),
      expect: () => [
        const PostState.loading(),
        PostState.loaded(testPosts),
      ],
      verify: (_) {
        verify(mockGetPosts(limit: null, offset: null)).called(1);
      },
    );

    blocTest<PostBloc, PostState>(
      '실패 시 loading → error 상태 전환',
      build: () {
        when(mockGetPosts(limit: anyNamed('limit'), offset: anyNamed('offset')))
            .thenAnswer((_) async => const Left(Failure.network('Network error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const PostEvent.loadPosts()),
      expect: () => [
        const PostState.loading(),
        const PostState.error('Network error'),
      ],
    );
  });
}
```

### 13.4 Widget 테스트

```dart
// test/features/posts/presentation/pages/posts_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';

void main() {
  late MockPostBloc mockBloc;

  setUp(() {
    mockBloc = MockPostBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<PostBloc>.value(
        value: mockBloc,
        child: const PostsView(),
      ),
    );
  }

  testWidgets('loading 상태일 때 CircularProgressIndicator 표시', (tester) async {
    // Arrange
    when(mockBloc.state).thenReturn(const PostState.loading());

    // Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('loaded 상태일 때 포스트 목록 표시', (tester) async {
    // Arrange
    final testPosts = [
      const Post(
        id: '1',
        title: 'Test Post',
        content: 'Content',
        author: User(id: '1', name: 'Author', email: 'test@test.com'),
        comments: [],
        createdAt: '2026-01-01',
        updatedAt: '2026-01-01',
      ),
    ];

    when(mockBloc.state).thenReturn(PostState.loaded(testPosts));

    // Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Assert
    expect(find.text('Test Post'), findsOneWidget);
    expect(find.text('Author'), findsOneWidget);
  });

  testWidgets('error 상태일 때 에러 메시지 표시', (tester) async {
    // Arrange
    when(mockBloc.state).thenReturn(const PostState.error('Network error'));

    // Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Assert
    expect(find.text('Error: Network error'), findsOneWidget);
  });
}
```

## 14. Best Practices

### 14.1 Do's and Don'ts

| Do | Don't |
|----|-------|
| Query에는 `cacheAndNetwork` 정책 사용 | 모든 요청에 `networkOnly` 사용 |
| Fragment로 재사용 가능한 필드 정의 | 중복된 필드 정의 반복 |
| Mutation 후 캐시 수동 업데이트 | 캐시 업데이트 없이 refetch만 의존 |
| Optimistic UI로 사용자 경험 개선 | 모든 응답 대기 후 UI 업데이트 |
| Either 패턴으로 명시적 에러 처리 | try-catch만 사용 |
| 타입 안전성 위해 Ferry/Code Generation 활용 | 동적 타입만 사용 |
| Subscription으로 실시간 기능 구현 | 폴링으로 실시간 흉내 |
| Pagination으로 대량 데이터 처리 | 모든 데이터 한 번에 로드 |
| Repository 패턴으로 GraphQL 로직 분리 | UI에서 직접 GraphQL 호출 |
| 테스트 시 Mock GraphQL Client 사용 | 실제 서버 의존 테스트 |

### 14.2 성능 최적화

**1. Query 최적화:**
```graphql
# Bad: 불필요한 필드 요청
query GetPosts {
  posts {
    id
    title
    content
    author {
      id
      name
      email
      bio
      avatar
      followers { ... }
      following { ... }
    }
    comments { ... }
  }
}

# Good: 필요한 필드만 요청
query GetPosts {
  posts {
    id
    title
    author {
      name
    }
  }
}
```

**2. Pagination 필수:**
```dart
// 대량 데이터는 반드시 pagination 적용
QueryOptions(
  document: gql(query),
  variables: {'limit': 20, 'offset': 0},
)
```

**3. 캐시 활용:**
```dart
// 자주 변경되지 않는 데이터는 캐시 우선
fetchPolicy: FetchPolicy.cacheFirst,

// 최신 데이터 필요하지만 빠른 로딩도 중요할 때
fetchPolicy: FetchPolicy.cacheAndNetwork,
```

**4. Debounce 검색:**
```dart
Timer? _debounce;

void _onSearchChanged(String query) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 500), () {
    // GraphQL 검색 실행
  });
}
```

### 14.3 보안 고려사항

**1. 인증 토큰 관리:**
```dart
final authLink = AuthLink(
  getToken: () async {
    // Secure storage에서 토큰 가져오기
    final token = await secureStorage.read(key: 'auth_token');
    return token != null ? 'Bearer $token' : null;
  },
);
```

**2. Sensitive 데이터 캐싱 방지:**
```dart
// 민감한 데이터는 캐시하지 않음
QueryOptions(
  document: gql(sensitiveQuery),
  fetchPolicy: FetchPolicy.networkOnly,
)
```

**3. Input Validation:**
```dart
// 사용자 입력 검증
if (!_isValidInput(input)) {
  return Left(const Failure.validation('Invalid input'));
}

final result = await createPost(sanitize(input));
```

**4. Rate Limiting:**
```dart
// 과도한 요청 방지
final rateLimiter = RateLimiter(
  maxRequests: 10,
  duration: const Duration(seconds: 60),
);

if (!await rateLimiter.allow()) {
  return Left(const Failure.rateLimit('Too many requests'));
}
```

### 14.4 디버깅 팁

**1. GraphQL Logging:**
```dart
final link = HttpLink(
  endpoint,
  defaultHeaders: {'Content-Type': 'application/json'},
).concat(
  LoggingLink(
    requestSerializer: (request) {
      print('GraphQL Request: ${request.operation.operationName}');
      print('Variables: ${request.variables}');
      return request;
    },
    responseParser: (response) {
      print('GraphQL Response: ${response.data}');
      if (response.errors != null) {
        print('Errors: ${response.errors}');
      }
      return response;
    },
  ),
);
```

**2. DevTools 활용:**
```dart
// Chrome DevTools에서 GraphQL 네트워크 요청 확인
// Application > Local Storage > graphql-cache 확인
```

**3. 에러 추적:**
```dart
// Sentry 등 에러 추적 서비스 연동
result.fold(
  (failure) {
    Sentry.captureException(failure);
    return Left(failure);
  },
  (data) => Right(data),
);
```

---

이 가이드는 Flutter에서 GraphQL을 활용한 현대적인 앱 개발의 모든 측면을 다룹니다. Clean Architecture, Bloc 패턴, 타입 안전성을 갖춘 확장 가능하고 유지보수 가능한 애플리케이션을 구축할 수 있습니다.
