module Api
  module V1
    module User
      class CheckStatusController < ApplicationController
        rescue_from CheckStatusParams::Invalid, with: :render_invalid_params

        def create
          check_params = CheckStatusParams.new(
            params,
            headers: request.headers,
            remote_ip: request.remote_ip
          )

          result = CheckStatusService.new(
            idfa: check_params.idfa,
            rooted_device: check_params.rooted_device,
            ip: check_params.ip,
            country: check_params.country
          ).call

          render json: result
        end

        private

        def render_invalid_params(exception)
          render json: { error: exception.message }, status: :unprocessable_entity
        end
      end
    end
  end
end
