FactoryBot.define do
  factory :clusters_applications_helm, class: Clusters::Applications::Helm do
    cluster factory: %i(cluster provided_by_gcp)

    trait :not_installable do
      status(-2)
    end

    trait :installable do
      status 0
    end

    trait :scheduled do
      status 1
    end

    trait :installing do
      status 2
    end

    trait :installed do
      status 3
    end

    trait :errored do
      status(-1)
      status_reason 'something went wrong'
    end

    trait :rbac_enabled_cluster do
      after(:create) do |app, _evaluator|
        app.cluster.platform_kubernetes.authorization_type = 'rbac'
      end
    end

    trait :timeouted do
      installing
      updated_at ClusterWaitForAppInstallationWorker::TIMEOUT.ago
    end

    factory :clusters_applications_ingress, class: Clusters::Applications::Ingress do
      cluster factory: %i(cluster with_installed_helm provided_by_gcp)
    end

    factory :clusters_applications_prometheus, class: Clusters::Applications::Prometheus do
      cluster factory: %i(cluster with_installed_helm provided_by_gcp)
    end

    factory :clusters_applications_runner, class: Clusters::Applications::Runner do
      cluster factory: %i(cluster with_installed_helm provided_by_gcp)
    end

    factory :clusters_applications_jupyter, class: Clusters::Applications::Jupyter do
      oauth_application factory: :oauth_application
      cluster factory: %i(cluster with_installed_helm provided_by_gcp)
    end
  end
end
